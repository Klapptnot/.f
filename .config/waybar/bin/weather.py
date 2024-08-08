#!/usr/bin/env python3

import os
import sys
import json
import urllib.parse
import urllib3
from datetime import datetime

WEATHER_CODES = {
    "113": "☀️",
    "116": "⛅",
    "119": "⛅",
    "122": "⛅",
    "143": "⛅",
    "176": "🌦️",
    "179": "🌦️",
    "182": "🌦️",
    "185": "🌦️",
    "200": "⛈️",
    "227": "🌨️",
    "230": "🌨️",
    "248": "☁️ ",
    "260": "☁️",
    "263": "🌧️",
    "266": "🌧️",
    "281": "🌧️",
    "284": "🌧️",
    "293": "🌧️",
    "296": "🌧️",
    "299": "🌧️",
    "302": "🌧️",
    "305": "🌧️",
    "308": "🌧️",
    "311": "🌧️",
    "314": "🌧️",
    "317": "🌧️",
    "320": "🌨️",
    "323": "🌨️",
    "326": "🌨️",
    "329": "❄️",
    "332": "❄️",
    "335": "❄️",
    "338": "❄️",
    "350": "🌧️",
    "353": "🌧️",
    "356": "🌧️",
    "359": "🌧️",
    "362": "🌧️",
    "365": "🌧️",
    "368": "🌧️",
    "371": "❄️",
    "374": "🌨️",
    "377": "🌨️",
    "386": "🌨️",
    "389": "🌨️",
    "392": "🌧️",
    "395": "❄️",
}


def format_time(time):
    return time.replace("00", "").zfill(2)


def format_temp(temp):
    return (temp + "°").ljust(3)


def format_chances(hour):
    chances = {
        "chanceoffog": "Fog",
        "chanceoffrost": "Frost",
        "chanceofovercast": "Overcast",
        "chanceofrain": "Rain",
        "chanceofsnow": "Snow",
        "chanceofsunshine": "Sunshine",
        "chanceofthunder": "Thunder",
        "chanceofwindy": "Wind",
    }

    conditions = []
    for event in chances.keys():
        if int(hour[event]) > 0:
            conditions.append(chances[event] + " " + hour[event] + "%")
    return ", ".join(conditions)

def generate_tooltip_str(weather: dict) -> str:
    # <b>Athenas: Clear 26°</b>
    tooltip = (
        "<b>"
        + f"{weather['nearest_area'][0]['areaName'][0]['value']}: "
        + f"{weather['current_condition'][0]['weatherDesc'][0]['value']} "
        + f"{weather['current_condition'][0]['temp_C']}°"
        + "</b>\n"
    )
    tooltip += f"Feels like: {weather['current_condition'][0]['FeelsLikeC']}°\n"
    tooltip += f"Wind: {weather['current_condition'][0]['windspeedKmph']}Km/h\n"
    tooltip += f"Humidity: {weather['current_condition'][0]['humidity']}%\n"
    for i, day in enumerate(weather["weather"]):
        tooltip += "\n<b>"
        if i == 0:
            tooltip += "Today, "
        if i == 1:
            tooltip += "Tomorrow, "
        tooltip += f"{day['date']}</b>\n"
        tooltip += f"⬆️{day['maxtempC']}° ⬇️{day['mintempC']}° "
        tooltip += (
            f"🌅{day['astronomy'][0]['sunrise']} 🌇{day['astronomy'][0]['sunset']}\n"
        )

        for hour in day["hourly"]:
            if i == 0:
                if int(format_time(hour["time"])) < datetime.now().hour - 2:
                    continue
            tooltip += (
                f"{format_time(hour['time'])} {WEATHER_CODES[hour['weatherCode']]} {format_temp(hour['FeelsLikeC'])} {hour['weatherDesc'][0]['value'].strip()}, {format_chances(hour)}\n"
            )
    return tooltip


def make_waybar_json(weather: dict) -> str:
    data = {}

    tempint = int(weather["current_condition"][0]["FeelsLikeC"])
    extrachar = ""
    if tempint > 0 and tempint < 10:
        extrachar = "+"

    data["text"] = (
        " "
        + WEATHER_CODES[weather["current_condition"][0]["weatherCode"]]
        + " "
        + extrachar
        + weather["current_condition"][0]["FeelsLikeC"]
        + "°"
    )
    data["alt"] = weather["nearest_area"][0]["areaName"][0]["value"]
    data["tooltip"] = generate_tooltip_str(weather)

    return json.dumps(data)


def make_hyprlock_fmt(weather) -> str:
    return f"<b><big>{WEATHER_CODES[weather["current_condition"][0]["weatherCode"]]}</big> Feels like <big>{weather["current_condition"][0]["FeelsLikeC"]}°</big></b>"


def main() -> None:
    argv = sys.argv[1:]
    with open(os.path.expanduser("~/.geoinfo"), "r") as f:
        city = f.read().split("\n")[0]
    city = urllib.parse.quote(city)
    http = urllib3.PoolManager().request("GET", f"https://wttr.in/{city}?format=j1", headers={})
    weather = json.loads(http.data.decode("utf-8"))

    if len(argv) > 0 and argv[0] == "lockscreen":
        print(make_hyprlock_fmt(weather))
    else:
        print(make_waybar_json(weather))

if __name__ == "__main__":
    main()
