import re
import urllib

def mark(text, args, Mark, extra_cli_args, *a):
    # This function is responsible for finding all
    # matching text. extra_cli_args are any extra arguments
    # passed on the command line when invoking the kitten.
    # We mark all individual word for potential selection
    for idx, m in enumerate(re.finditer(r'(?ms)(?:console.log)(.*?)(?:at Console)', text)):
        initial_start = m.start(1)
        inital_end = m.end(1)
        matched_text = m.group(1)
        inner_match = re.search('(?ms){.*}', matched_text)
        extra_start, extra_end = inner_match.span()
        mark_text = inner_match.group(0).replace('\n', '').replace('\0', '')
        start = initial_start + extra_start
        end = initial_start + extra_end

        # The empty dictionary below will be available as groupdicts
        # in handle_result() and can contain arbitrary data.
        yield Mark(idx, start, end, mark_text, {})


def handle_result(args, data, target_window_id, boss, extra_cli_args, *a):
    # This function is responsible for performing some
    # action on the selected text.
    # matches is a list of the selected entries and groupdicts contains
    # the arbitrary data associated with each entry in mark() above
    matches, groupdicts = [], []
    for m, g in zip(data['match'], data['groupdicts']):
        if m:
            matches.append(m), groupdicts.append(g)
    for json_text, match_data in zip(matches, groupdicts):
        queryText=urllib.parse.quote_plus(json_text)
        # Lookup the word in a dictionary, the open_url function
        # will open the provided url in the system browser
        boss.open_url(f'https://jsonlint.com/?json={queryText}')
