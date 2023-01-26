const default_title = "megatab";
const loading_indicator = "…";
const shrug_indicator = "¯\\_(ツ)_/¯";

const loader = (parent, enabled, indicator) => {
  indicator = indicator || loading_indicator;
  const parentEl =
    (typeof parent == "string" && document.querySelector(parent)) || parent;
  let loaderEl;

  if (parent && parentEl) {
    if (enabled) {
      loaderEl = document.createElement("small");
      loaderEl.classList.add("loader");
      loaderEl.innerText = indicator;
      parentEl.prepend(loaderEl);
    } else {
      loaderEl = document.querySelector(".loader");
      if (loaderEl) {
        loaderEl.remove();
      }
    }
  }
};

async function get(url) {
  console.debug(`querying ${url}`);
  const response = await fetch(url, {
    method: "GET",
  });
  if (!response.ok) {
    document.title = `${default_title}`;
    throw new Error(`HTTP error! status: ${response.status}`);
  }
  const data = await response.json();
  return data;
}

const ip = () => {
  const ipEl = document.querySelector("#ip");
  loader(ipEl, true);
  get("https://api.ipify.org?format=json").then((data) => {
    if (typeof data !== "undefined") {
      ipEl.innerText = data.ip;
      loader(ipEl, false);
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
      }, 2000);
    });
  }
};

// REF: https://pirateweather.net/?utm_source=hackernewsletter&utm_medium=email&utm_term=show_hn
const weather = (enabled) => {
  if (enabled) {
    const wEl = document.querySelector("#weather");
    const request = () => {
      loader(wEl, true);
      get("https://wttr.in?u&format=j1")
        .then((data) => {
          if (typeof data !== "undefined") {
            const w = data.current_condition[0];
            loader(wEl, false);

            wEl.querySelector("span").innerText = `${w.temp_F}°`;
            document.title = `${default_title} (${w.temp_F}°)`; // ⋮
            if (w.temp_F !== w.FeelsLikeF) {
              wEl.querySelector("strong").innerText = `(${w.FeelsLikeF}°)`;
            }
            if (w.weatherDesc[0].value !== "") {
              wEl.querySelector("em").innerText = `${w.weatherDesc[0].value}`;

              // REF:
              // - https://unicode-table.com/en/emoji/travel-and-places/sky-and-weather/
              // - https://www.alt-codes.net/weather-symbols.php
              // - https://github.com/chubin/wttr.in/issues/130#issuecomment-313024249
              switch (w.weatherDesc[0].value) {
                case "Sunny":
                  wEl.querySelector("em").style = "color: orange;";
                  break;
                case "Partly cloudy":
                  wEl.querySelector("em").style =
                    "background: linear-gradient(to right, #B5E0FC, #F3BD53); -webkit-background-clip: text; -webkit-text-fill-color: transparent;";
                  break;
                case "Mist":
                  wEl.querySelector("em").style =
                    "background: linear-gradient(to bottom, #7FC7FA, #FFFFFF 65%); -webkit-background-clip: text; -webkit-text-fill-color: transparent;";
                  break;
                case "Light rain":
                  wEl.querySelector("em").innerHTML =
                    wEl.querySelector("em").innerHTML + " &#x1F327;";
                  break;
                case "Rain, mist":
                  wEl.querySelector("em").style =
                    "background: linear-gradient(90deg, #3377B6, #ffffff 85%); -webkit-background-clip: text; -webkit-text-fill-color: transparent;";
                  wEl.querySelector("em").innerHTML =
                    wEl.querySelector("em").innerHTML + " &#x1F327;";
                case "Overcast":
                  wEl.querySelector("em").style =
                    "background: linear-gradient(to bottom, #666666, #ffffff 85%); -webkit-background-clip: text; -webkit-text-fill-color: transparent;";
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
        })
        .catch(() => {
          document.title = `${default_title}`;
          loader(wEl, true, shrug_indicator);
        });
    };
    request();

    const delay = 1000 * 60 * 15;
    window.setInterval(request, delay);
  }
};

const focus = (selector) => {
  document.querySelector(selector).focus();
};

const stars = (user) =>
  get(`https://api.github.com/users/${user}/starred`).then((data) => {
    if (typeof data !== "undefined") {
      console.log({ raw: data });
      const starred = data.map((s) => ({
        origin_user: s.owner.login,
        origin_id: s.id,
        origin_url: s.html_url,
        origin_created_at: s.created_at,
        content: s.description,
        title: s.name,
        tags: s.topics.concat(s.language),
        meta: {
          isFork: s.fork,
          git_url: s.git_url,
          ssh_url: s.ssh_url,
          repo_name: s.name,
          repo_full_name: s.full_name,
        },
      }));

      console.log({ starred });
    }
  });

const handleLoaded = () => {
  mimic(false);
  ip(true);
  weather(true);
  // focus("#test");
  //
  window.stars = stars;
};

if (["complete", "loaded", "interactive"].indexOf(document.readyState) >= 0) {
  handleLoaded();
} else {
  document.addEventListener("DOMContentLoaded", () => handleLoaded());
}
