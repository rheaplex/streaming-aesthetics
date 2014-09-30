# art_is.py - Tweeted definitions (and similar) of art in (oversized) console.
# Copyright (C) 2014 Rob Myers rob@robmyers.org
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.


################################################################################
# Imports
################################################################################

import re

from TwitterAPI import TwitterAPI
from urllib3.exceptions import ProtocolError

import auth_secrets as auth


################################################################################
# Config
################################################################################

PADDING = '    '
ART_IS = 'art is'


################################################################################
# Statement processing
################################################################################

def strip(text):
    # If the phrase ended http://, remove the part that was before the :
    no_http = re.sub('http', '', text)
    # Remove newlines and multi-spaces
    collapsed_whitespace = re.sub('\s+', ' ', no_http)
    # Remove any resulting trailing whitespace
    depadded = collapsed_whitespace.strip()
    # If the phrase was in single quotes, remove the closing one
    dequoted = depadded.strip("'")
    return dequoted

def process_match(tweet):
    text = tweet[u'text'].lower()
    # Match at the start of tweet or sentence, stop before any url
    match = re.search(r'\bart\s+is\s+([\s\w\']+)(http)?', text)
    # If there's an actual "art is..." phrase rather than just an art+is match
    if match:
        art_is = strip(match.group(1))
        # If we didn't strip everything
        if art_is != "":
            print "%s%s %s" % (PADDING, ART_IS, art_is)


################################################################################
# Main loop
################################################################################

def main_loop():
    api = TwitterAPI(auth.consumer_key, auth.consumer_secret,
                     auth.access_token_key, auth.access_token_secret)
    while True:
        try:
            r = api.request('statuses/filter', {'track': 'art is'})
            for item in r.get_iterator():
                process_match(item)
        except ProtocolError:
            time.sleep(1)


################################################################################
# Main flow of execution
################################################################################

main_loop()
