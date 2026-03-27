{mkApp}:
mkApp {
  pname = "fantastical";
  # version = "4.1.10";
  # version = "3.8.23";
  version = "2.5.16";
  # appName = "Fantastical.app";
  appName = "Fantastical 2.app";
  src = {
    # url = "https://cdn.flexibits.com/Fantastical_3.8.23.zip";
    # sha256 = "sha256-UBp9hl7amDWMjbwHQZ+otJNZvyn9z3lZ37nd2MfSe5w=";
    url = "https://cdn.flexibits.com/Fantastical_2.5.16.zip";
    sha256 = "sha256-sa4RWfZp7XKnu1eSCv3SfNk8/FxmyXMcgTevp5v/A+g=";
  };
  # appLocation = "copy"; # Needs /Applications for code signing
  desc = "Calendar and tasks app";
  homepage = "https://flexibits.com/fantastical";
}
