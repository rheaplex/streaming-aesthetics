#!/usr/bin/python

import tweetstream
import utilities

# The save file. Must be a full or fully resolvable path
SAVE_FILE = "./cached_print_stream_terms.json"

# The category terms we search for and count
COLOURS = ["red", "yellow", "blue"]
SHAPES = ["circle", "triangle", "square"]
PATTERNS = ["stripe", "dot", "check"]
TERMS = COLOURS + SHAPES + PATTERNS
CATEGORIES = {"colour": COLOURS, "shape": SHAPES, "pattern": PATTERNS}

# Start the counts at a value that won't show sudden proportional changes
# when we first begin adding to it
COUNT_DEFAULT = 10

#TODO Can we hide the password?
username = str(raw_input("Twitter username:"))
password = utilities.getpass("Twitter password:")

def category_total_count(counts, category_keys):
    """Get the total of all the counts for all the keys in the category"""
    total = 0
    for key in category_keys:
        total += counts.get(key, 0)
    return total

def report_category_counts(counts, categories):
    """Report on the proportion counts for each category"""
    for category_name in categories.keys():
        print(category_name)
        category_terms = categories[category_name]
        category_total = category_total_count(counts, category_terms)
        for term in category_terms:
            print "%s: %s/%s\t\t" % (term, counts[term], category_total),
        print
    print

def go():
    try:
        counts = utilities.deserialise_counts(SAVE_FILE)
    except:
        counts = utilities.create_counts(TERMS, COUNT_DEFAULT)
    tty = utilities.TweetCurses()
    stream = tweetstream.TrackStream(username, password, TERMS)
    for tweet in stream:
        tweet_text = tweet["text"]
        terms_in_tweet = utilities.terms_in(TERMS, tweet_text)
        # If we didn't get a spuriously reported tweet...
        if terms_in_tweet:
            tty.clear()
            # Print anything else with the tweet text? Pass it to pad, too...
            print tweet_text
            tty.pad_tweet_rows(tweet_text)
            utilities.increase_counts(counts, terms_in_tweet)
            utilities.serialise_counts(SAVE_FILE, counts)
            print "Terms: %s" % (" ".join(terms_in_tweet))
            report_category_counts(counts, CATEGORIES)
        # Otherwise, ignore......
        #else:
        #    print "SPURIOUS"

go()
