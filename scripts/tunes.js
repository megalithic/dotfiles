function truncate(str, limit) {
  if (str.length > limit) {
    const trimmed = `${str.substr(0, limit)}`.trim();
    str = `${trimmed}…`;
  } else {
    return str;
  }
  return str;
}

let output = "";
if (Application("Music").running()) {
  const track = Application("Music").currentTrack;
  const artist = track.artist();
  const title = track.name();
  output = truncate(`${stateIcon} ${artist} - ${title}`, 45);
} else if (Application("Spotify").running()) {
  const player = Application("Spotify");
  const track = player.currentTrack;
  const artist = track.artist().replace("#S", "S");
  const title = track.name().replace("#S", "S");
  const state = player.playerState();

  let stateIcon = "";
  if (state === "playing") {
    stateIcon = ""; // alts:  
  } else {
    stateIcon = ""; // alts:  
  }

  output = truncate(`${stateIcon} ${artist} - ${title}`, 45);
}

output;
