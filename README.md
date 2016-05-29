##SmartReaderiOS##

Smart Reader is a RSS app with intelligence :)

Smart Reader does what any standard RSS app does, but also applies machine learning algorithms to the news items, in order to suggest to the user what to read first among a sea of articles.

###Features###

* Add/remove/update RSS feeds.

* Have a comfortable, elegant user interface.

* Use bayesian text filtering algorithm (similar to spam filtering), combined with PageRank algorithm to determine if a news article falls into user’s interest.

* Filter out similar news reports from different sources.

* Runs smoothly on iPhone, iPad.  With future Mac port.

* Show summary text for news articles if there are any.  Else, directly show the news article, but with button to render through readability mobilizer.

###Future Features###

* Online plans (paid services):
	- Better recommendation through friend’s suggestions.
	- Better recommendation from friend’s shared interests (sharing interest concept?).

* Backup interest db to iCloud.

###Technology###

* Use GCD as much as possible, along with async and background processing techniques to reduce impact to app’s UI thread.

* From user input URL, parse page to determine if it is feed (Atom/RSS), or HTML.
	- If URL points to a feed, parse the feed, and add the URL to feed library.
	- If URL points to HTML, parse HTML for feed URL, then carry out step 1.
