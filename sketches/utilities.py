import curses
import math
import os
import simplejson
import sys
import termios

# from http://docs.python.org/library/termios.html
def getpass(prompt="Password: "):
    import termios, sys
    fd = sys.stdin.fileno()
    old = termios.tcgetattr(fd)
    new = termios.tcgetattr(fd)
    new[3] = new[3] & ~termios.ECHO          # lflags
    try:
        termios.tcsetattr(fd, termios.TCSADRAIN, new)
        passwd = raw_input(prompt)
    finally:
        termios.tcsetattr(fd, termios.TCSADRAIN, old)
    return passwd

class TweetCurses(object):
    """Format up a tweet message at the top of a terminal screen."""
    def __init__(self, rows=6):
        curses.setupterm()
        self.clear_command = curses.tigetstr('clear')
        self.columns = curses.tigetnum('cols')
        self.rows = rows

    def clear(self):
        sys.stdout.write(self.clear_command)

    def max_tweet_rows(self):
        return int(math.ceil(140.0 / self.columns)) + self.rows

    def tweet_padding_rows(self, tweet_text):
        # If this ends up negative, pad_tweet_rows will print 0 so it's OK
        return (self.max_tweet_rows() - \
                    int(math.ceil(float(len(tweet_text)) / self.columns))) - \
                    self.newline_count(tweet_text)

    def newline_count(self, tweet_text):
        return tweet_text.count("\n") + tweet_text.count("\r")

    def pad_tweet_rows(self, tweet_text):
        for i in range(0, self.tweet_padding_rows(tweet_text)):
            print

def serialise_counts(filename, terms):
    temp_filename = filename + "tmp"
    temp_file = open(temp_filename, 'w')
    simplejson.dump(terms, temp_file)
    temp_file.close()
    os.rename(temp_filename, filename)
    
def deserialise_counts(filename):
    """Deserialize the saved state file. (Dies if it's not there)"""
    dump_file = open(filename)
    return simplejson.load(dump_file)

def terms_in(terms, tweet_text):
    """Return a list of the terms the tweet text contains"""
    contains = []
    for term in terms:
        if term in tweet_text.lower():
            contains.append(term)
    return contains

def increase_counts(counts, keys):
    """Increment the counts"""
    for key in keys:
        counts[key] = counts.get(key, 0) + 1

def create_counts(keys, default):
    """Create the default counts"""
    counts = {}
    for key in keys:
        counts[key] = default
    return counts
