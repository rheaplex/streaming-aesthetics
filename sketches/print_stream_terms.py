#!/usr/bin/python

import os
import simplejson
import tweetstream

# The save file. Must be a full or fully resolvable path
SAVE_FILE = "./print_stream_terms.save"

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
password = str(raw_input("Twitter password:"))

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

def serialise_counts(terms):
    temp_filename = SAVE_FILE + "tmp"
    temp_file = open(temp_filename, 'w')
    simplejson.dump(terms, temp_file)
    temp_file.close()
    os.rename(temp_filename, SAVE_FILE)
    
def deserialise_counts():
    """Deserialize the saved state file. (Dies if it's not there)"""
    dump_file = open(SAVE_FILE)
    return simplejson.load(dump_file)
    
def go():
    try:
        counts = deserialise_counts()
    except:
        counts = create_counts(TERMS, COUNT_DEFAULT)
    stream = tweetstream.TrackStream(username, password, TERMS)
    for tweet in stream:
        tweet_text = tweet["text"]
        terms_in_tweet = terms_in(TERMS, tweet_text)
        # If we didn't get a spuriously reported tweet...
        if terms_in_tweet:
            increase_counts(counts, terms_in_tweet)
            serialise_counts(counts)
            print "Tweet: %s" % (tweet_text)
            print "Terms: %s" % (" ".join(terms_in_tweet))
            report_category_counts(counts, CATEGORIES)
        else:
            print "SPURIOUS TWEET: %s" % (tweet_text)
go()
