let output = "";
if (Application("Music").running()) {
  const track = Application("Music").currentTrack;
  const artist = track.artist();
  const title = track.name();
  output = `${title} - ${artist}`.substr(0, 50);
} else if (Application("Spotify").running()) {
  const player = Application("Spotify");
  const track = player.currentTrack;
  const artist = track.artist();
  const title = track.name();

  const state = player.playerState();
  let stateIcon = "";
  if (state === "playing") {
    stateIcon = ""; // alts:  
  } else {
    stateIcon = ""; // alts:  
  }

  output = `${stateIcon} ${artist} - ${title}`.substr(0, 50);
}

output;
