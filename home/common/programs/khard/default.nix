# khard - command-line address book (CardDAV)
{...}: {
  programs.khard = {
    enable = true;
    settings = {
      "contact table" = {
        display = "formatted_name";
        preferred_phone_number_type = ["pref" "mobile" "cell"];
        preferred_email_address_type = ["pref" "work" "home"];
      };
    };
  };
}
