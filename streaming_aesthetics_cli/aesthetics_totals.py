# aesthetics_totals.py - Report Twitter aesthetics terms in (oversized) console.
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

# Thanks to Jim Andrews for additional net art terms.

################################################################################
# Imports
################################################################################

import curses, datetime, re, sys, time

from TwitterAPI import TwitterAPI
from urllib3.exceptions import ProtocolError

import auth_secrets as auth


################################################################################
# Configuration
################################################################################

# How often to update the screen
REPORT_FREQUENCY = 1

COLOURS = 'black,white,grey,gray,red,orange,yellow,green,blue,purple,cyan,magenta,pink,brown,beige,violet,indigo'
COLOURS_LIST = COLOURS.split(',')
FORMS = 'point,line,circle,triangle,square,star,spiral,grid'
FORMS_LIST = FORMS.split(',')
MEDIA = 'painting,drawing,printmaking,sculpture,video art,sound art,performance art,installation art,digital art,conceptual art'
MEDIA_LIST = MEDIA.split(',')
NET_ART = 'varporwave,glitch,gif,cyberpunk,net art,ascii art,game art,locative media,code poetry,generative art'
NET_ART_LIST = NET_ART.split(',')
ARTISTS = 'Yayoi Kusama,Barbara Kruger,Richard Serra,Jeff Koons,Cindy Sherman,Ai Weiwei,Takashi Murakami,Marina Abramovic,Banksy,Damien Hirst'
ARTISTS_LIST = ARTISTS.split(',')
INSTITUTIONS = 'Tate,Getty,MOMA,ICA,LACMA,Prado,Louvre,Uffizi,Saatchi Gallery,Rijksmuseum'
INSTITUTIONS_LIST = INSTITUTIONS.split(',')

COLUMN_FORMAT = '{0:<16} {1:>8}'
COLUMN_TEXT_WIDTH = 25  # See COLUMN_FORMAT
COLUMN_PADDING = 8
COLUMN_WIDTH = COLUMN_TEXT_WIDTH + COLUMN_PADDING
COLUMN_SEPARATOR = '@@@@'
TITLE_SEPARATOR = '-' * COLUMN_TEXT_WIDTH
PRINT_LIST = ['COLOURS', TITLE_SEPARATOR] + COLOURS_LIST \
             + ['', 'FORMS', TITLE_SEPARATOR] + FORMS_LIST \
             + [COLUMN_SEPARATOR] \
             + ['MEDIA', TITLE_SEPARATOR] + MEDIA_LIST \
             + ['', 'NET ART', TITLE_SEPARATOR] + NET_ART_LIST \
             + [COLUMN_SEPARATOR] \
             + ['ARTISTS', TITLE_SEPARATOR] + ARTISTS_LIST \
             + ['', 'INSTITUTIONS', TITLE_SEPARATOR] + INSTITUTIONS_LIST

KEYWORDS = ','.join([COLOURS, FORMS, MEDIA, NET_ART, ARTISTS, INSTITUTIONS])
KEYWORDS_LIST = COLOURS_LIST + FORMS_LIST + MEDIA_LIST + NET_ART_LIST \
                + ARTISTS_LIST + INSTITUTIONS_LIST
KEYWORD_MATCH = re.compile('(' + '|'.join(KEYWORDS_LIST) + ')')


#FIXME: Note the empty column at the end. Fix the logic that requires this...
COLUMN_HEIGHTS = [column.count(',') for column in [COLOURS, MEDIA, NET_ART]]
NUM_COLUMNS = len(COLUMN_HEIGHTS)
TOTAL_COLUMNS_WIDTH = NUM_COLUMNS * COLUMN_WIDTH
TOTAL_COLUMNS_HEIGHT =  30 # Count from highest column above


################################################################################
# Reporting
################################################################################

START_TIME = datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S")
HEADER_TITLE = "TOTALS SINCE " + START_TIME
HEADER_TITLE_WIDTH = len(HEADER_TITLE)

def print_counts(stdscr, keywords_counts):
    screen_offset_h = (stdscr.getmaxyx()[1] / 2) - (TOTAL_COLUMNS_WIDTH / 2)
    screen_offset_v = (stdscr.getmaxyx()[0] / 2) - (TOTAL_COLUMNS_HEIGHT / 2)
    row = 0
    column = 0
    stdscr.clear()
    stdscr.addstr(0, (stdscr.getmaxyx()[1] / 2) - (HEADER_TITLE_WIDTH / 2),
                  HEADER_TITLE)
    for key in PRINT_LIST:
        if key == COLUMN_SEPARATOR:
            column += 1
            row = 0
            continue
        try:
            value = keywords_counts[key]
            desc = COLUMN_FORMAT.format(key, value)
        except:
            desc = key
        column_h = screen_offset_h + (column * COLUMN_WIDTH)
        column_v = screen_offset_v + row
        stdscr.addstr(column_v, column_h, desc)
        row += 1
    stdscr.refresh()


################################################################################
# Processing
################################################################################

def process_matches(item, keywords_counts):
    matches = re.findall(KEYWORD_MATCH, item[u'text'].lower())
    for match in matches:
        keywords_counts[match] += 1


################################################################################
# Main event loop
################################################################################

def main_loop(stdscr):
    curses.curs_set(False)
    keywords_counts = dict(zip(KEYWORDS_LIST, [0] * len(KEYWORDS_LIST)))
    tweet_count = 0
    api = TwitterAPI(auth.consumer_key, auth.consumer_secret,
                     auth.access_token_key, auth.access_token_secret)
    while True:
        try:
            r = api.request('statuses/filter', {'track': KEYWORDS})
            for item in r.get_iterator():
                process_matches(item, keywords_counts)
                if tweet_count % REPORT_FREQUENCY == 0:
                    print_counts(stdscr, keywords_counts)
                tweet_count += 1
        except ProtocolError:
            time.sleep(1)


################################################################################
# Main flow of execution
################################################################################

curses.wrapper(main_loop)
