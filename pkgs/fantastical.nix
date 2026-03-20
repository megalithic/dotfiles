{mkApp}:

mkApp {
  pname = "fantastical";
  version = "4.1.10";
  appName = "Fantastical.app";
  src = {
    url = "https://cdn.flexibits.com/Fantastical_4.1.10.zip";
    sha256 = "sha256-HnwqXIVKhuhhek7o7lzkfV+pQlOwlZniRpbc8KNxYnI=";
  };
  appLocation = "copy"; # Needs /Applications for code signing
  desc = "Calendar and tasks app";
  homepage = "https://flexibits.com/fantastical";
}
