async function get(url) {
  console.debug(`querying ${url}`);
  const response = await fetch(url, {
    method: "GET",
  });
  if (!response.ok) {
    throw new Error(`HTTP error! status: ${response.status}`);
  }
  const data = await response.json();
  return data;
}

const ip = () => {
  get("https://api.ipify.org?format=json").then((data) => {
    if (typeof data !== "undefined") {
      document.querySelector("#ip").innerText = data.ip;
      clip(true);
    }
  });
};

const mimic = (enabled) => {
  if (enabled) {
    window.addEventListener("keydown", (e) => {
      console.log(e);
    });

    window.dispatchEvent(
      new KeyboardEvent("keydown", {
        key: "Escape",
      })
    );
  }
};

const clip = (enabled) => {
  if (enabled) {
    const ipEl = document.querySelector("#ip");
    const content = ipEl.innerText;
    let timeout;

    ipEl.parentElement.addEventListener("click", () => {
      navigator.clipboard.writeText(content);
      ipEl.innerHTML = content + " <strong class='confirmation'>✓</strong>";

      timeout = window.setTimeout(() => {
        document.querySelector("#ip").innerText = content;
        window.clearTimeout(timeout);
      }, 1000);
    });
  }
};

const weather = () => {
  const request = () => {
    get("https://wttr.in/hoover?u&format=j1").then((data) => {
      if (typeof data !== "undefined") {
        const w = data.current_condition[0];
        const wEl = document.querySelector("#weather");

        wEl.querySelector("span").innerText = `${w.temp_F}°`;
        if (w.temp_F !== w.FeelsLikeF) {
          wEl.querySelector("strong").innerText = `(${w.FeelsLikeF}°)`;
        }
        if (w.weatherDesc[0].value !== "") {
          wEl.querySelector("em").innerText = `${w.weatherDesc[0].value}`;
          switch (w.weatherDesc[0].value) {
            case "Sunny":
              wEl.querySelector("em").style = "color: orange;";
              break;
            default:
              console.debug(`weather condition: ${w.weatherDesc[0].value}`);
          }
        }

        const wIconUrl = w.weatherIconUrl[0].value;
        const wIconEl = wEl.querySelector("img");
        if (wIconUrl !== "") {
          wIconEl.classList.add("show");
          wIconEl.classList.remove("hide");
          wIconEl.setAttribute("src", wIconUrl);
        } else {
          wIconEl.classList.add("hide");
          wIconEl.classList.remove("show");
        }
      }
    });
  };
  request();

  const delay = 1000 * 60 * 15;
  window.setInterval(request, delay);
};

const handleLoaded = () => {
  mimic(false);
  ip(true);
  weather(true);
};

if (["complete", "loaded", "interactive"].indexOf(document.readyState) >= 0) {
  handleLoaded();
} else {
  document.addEventListener("DOMContentLoaded", () => handleLoaded());
}
