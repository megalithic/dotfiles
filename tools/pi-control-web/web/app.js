const elements = {
	back: document.querySelector("#back"),
	connection: document.querySelector("#connection"),
	detail: document.querySelector("#detail"),
	detailMeta: document.querySelector("#detail-meta"),
	detailState: document.querySelector("#detail-state"),
	detailTitle: document.querySelector("#detail-title"),
	latest: document.querySelector("#latest"),
	login: document.querySelector("#login"),
	loginForm: document.querySelector("#login-form"),
	messageForm: document.querySelector("#message-form"),
	notice: document.querySelector("#notice"),
	refresh: document.querySelector("#refresh"),
	sessionList: document.querySelector("#session-list"),
	sessions: document.querySelector("#sessions"),
	token: document.querySelector("#token"),
};

let sessions = [];
let selectedId = new URL(location.href).searchParams.get("session");
let detailRequest = 0;
let events;

const labelFor = (session) =>
	session.sessionName || session.tmux || "Pi session";

const stateLabel = (state) => (state || "idle").replaceAll("_", " ");

const setNotice = (message, isError = false) => {
	elements.notice.textContent = message;
	elements.notice.style.color = isError ? "#fca5a5" : "";
};

const api = async (url, options = {}) => {
	const response = await fetch(url, {
		credentials: "same-origin",
		...options,
		headers: {
			"Content-Type": "application/json",
			...(options.headers || {}),
		},
	});
	const body = await response.json().catch(() => ({}));
	if (!response.ok) {
		const error = new Error(
			body.error || `Request failed (${response.status})`,
		);
		error.status = response.status;
		throw error;
	}
	return body;
};

const showLogin = () => {
	detailRequest += 1;
	events?.close();
	events = undefined;
	elements.login.classList.remove("hidden");
	elements.sessions.classList.add("hidden");
	elements.detail.classList.add("hidden");
	elements.refresh.classList.add("hidden");
};

const showSessions = () => {
	detailRequest += 1;
	elements.login.classList.add("hidden");
	elements.detail.classList.add("hidden");
	elements.sessions.classList.remove("hidden");
	elements.refresh.classList.remove("hidden");
	selectedId = null;
	history.replaceState({}, "", "/");
};

const renderSessions = () => {
	elements.sessionList.replaceChildren();
	if (sessions.length === 0) {
		const empty = document.createElement("p");
		empty.className = "empty";
		empty.textContent = "No active Pi bridge sessions.";
		elements.sessionList.append(empty);
		return;
	}

	for (const session of sessions) {
		const button = document.createElement("button");
		const summary = document.createElement("span");
		const text = document.createElement("span");
		const name = document.createElement("strong");
		const project = document.createElement("span");
		const state = document.createElement("span");

		button.type = "button";
		button.className = "session-card";
		button.addEventListener("click", () => openSession(session.id));
		summary.className = "session-summary";
		name.textContent = labelFor(session);
		project.className = "project";
		project.textContent = [session.project, session.tmux]
			.filter(Boolean)
			.join(" · ");
		state.className = "state";
		state.dataset.state = session.state;
		state.textContent = stateLabel(session.state);

		text.append(name, project);
		summary.append(text, state);
		button.append(summary);
		elements.sessionList.append(button);
	}
};

const renderDetail = (session, message) => {
	elements.sessions.classList.add("hidden");
	elements.login.classList.add("hidden");
	elements.detail.classList.remove("hidden");
	elements.detailTitle.textContent = labelFor(session);
	elements.detailMeta.textContent = [session.project, session.tmux]
		.filter(Boolean)
		.join(" · ");
	elements.detailState.dataset.state = session.state;
	elements.detailState.textContent = stateLabel(session.state);
	elements.latest.textContent = message?.content || "No assistant message yet.";
};

const openSession = async (id) => {
	const request = ++detailRequest;
	selectedId = id;
	history.replaceState({}, "", `/?session=${encodeURIComponent(id)}`);
	elements.latest.textContent = "Loading latest response...";
	const session = sessions.find((candidate) => candidate.id === id);
	if (session) renderDetail(session, null);

	try {
		const data = await api(`/api/sessions/${encodeURIComponent(id)}/last`);
		if (selectedId !== id || request !== detailRequest) return;
		renderDetail(data.session, data.message);
	} catch (error) {
		if (selectedId !== id || request !== detailRequest) return;
		if (error.status === 401) showLogin();
		else setNotice(error.message, true);
	}
};

const applySnapshot = (snapshot) => {
	sessions = Array.isArray(snapshot) ? snapshot : [];
	renderSessions();
	elements.connection.textContent = "Live";
	if (selectedId) {
		const selected = sessions.find((session) => session.id === selectedId);
		if (selected) void openSession(selectedId);
		else showSessions();
	}
};

const connectEvents = () => {
	events?.close();
	events = new EventSource("/api/events");
	events.addEventListener("snapshot", (event) => {
		try {
			applySnapshot(JSON.parse(event.data));
		} catch {
			elements.connection.textContent = "Update error";
		}
	});
	events.addEventListener("open", () => {
		elements.connection.textContent = "Live";
	});
	events.addEventListener("error", () => {
		elements.connection.textContent = "Reconnecting";
	});
};

const loadSessions = async () => {
	try {
		const data = await api("/api/sessions");
		elements.login.classList.add("hidden");
		elements.sessions.classList.remove("hidden");
		elements.refresh.classList.remove("hidden");
		applySnapshot(data.sessions);
		connectEvents();
	} catch (error) {
		if (error.status === 401) showLogin();
		else setNotice(error.message, true);
	}
};

elements.loginForm.addEventListener("submit", async (event) => {
	event.preventDefault();
	setNotice("Signing in...");
	try {
		await api("/api/login", {
			method: "POST",
			body: JSON.stringify({ token: elements.token.value }),
		});
		elements.token.value = "";
		setNotice("");
		await loadSessions();
	} catch (error) {
		setNotice(error.message, true);
	}
});

elements.messageForm.addEventListener("submit", async (event) => {
	event.preventDefault();
	if (!selectedId) return;
	const form = new FormData(elements.messageForm);
	const text = String(form.get("message") || "").trim();
	const mode = String(form.get("mode") || "follow_up");
	if (!text) return;

	const submit = elements.messageForm.querySelector("button[type='submit']");
	submit.disabled = true;
	setNotice("Sending...");
	try {
		const result = await api(
			`/api/sessions/${encodeURIComponent(selectedId)}/messages`,
			{
				method: "POST",
				body: JSON.stringify({ text, mode }),
			},
		);
		elements.messageForm.reset();
		setNotice(`Accepted as ${result.deliveredAs || mode}.`);
	} catch (error) {
		setNotice(error.message, true);
	} finally {
		submit.disabled = false;
	}
});

elements.back.addEventListener("click", showSessions);
elements.refresh.addEventListener("click", loadSessions);

if ("serviceWorker" in navigator) {
	navigator.serviceWorker.register("/service-worker.js").catch(() => {});
}

void loadSessions();
