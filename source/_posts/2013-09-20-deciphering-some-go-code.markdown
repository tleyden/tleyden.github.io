---
layout: post
title: "Deciphering some Go code"
date: 2013-09-20 11:11
comments: true
categories: [golang]
---

While trying to use [couch-go](http://godoc.org/code.google.com/p/dsallings-couch-go) and looking at the source, I've come across some things I don't understand.

# Is function wrapper needed?

```
resp, err := client.Get(full_url)
log.Printf("resp: %v err: %v", resp, err)
if err == nil {
    func() {
        defer resp.Body.Close()
        defer conn.Close()

        tc := timeoutClient{resp.Body, conn, timeout}
        largest = handler(&tc)
    }()
} else {
    log.Printf("Error in stream: %v", err)
    time.Sleep(time.Second * 1)
}

```

Why the separate function wrapper here?  Why not just call:

```
defer resp.Body.Close()
defer conn.Close()
tc := timeoutClient{resp.Body, conn, timeout}
largest = handler(&tc)
```

directly?

# How to elegantly dump a request body?

I was trying to debug something, and I wanted to print out the json string before it was being parsed, and here's what I ended up doing:

```
body, err0 := ioutil.ReadAll(r.Body)
bodyStr := string(body)
log.Printf("body: %v err: %v", bodyStr, err0)
newBody := bytes.NewBuffer(body)
d := json.NewDecoder(newBody)
// d := json.NewDecoder(r.Body) <-- orig code
if err := d.Decode(results); err != nil {
    log.Printf("Decode err: %v", err)
    return err
}
```

it seems like there should be a slicker way, like maybe rewinding the r.Body Reader?

**Answer**: yes, there is a _much_ slicker way, `io.TeeReader`

```
d := json.NewDecoder(io.TeeReader(r.Body, os.Stdout))
```

# Using new() with a map -- does this look right?

According to "The Way To Go" (book), you are not supposed to be using new() with maps.  However I did this in one case:

```
type Document map[string]interface{}

func (game Game) fetchLatestGameDoc() (doc Document, err error) {
        fetchedDoc := new(Document)
        err = game.db.Retrieve(GAME_DOC_ID, fetchedDoc)
        if err == nil {
	   doc = *fetchedDoc
        }
        return
}

```

is there a better way?  When I tried using make(), I got the error `err: json: Unmarshal(non-pointer checkerlution.Document)`.  Using make() followed by & didn't work either.

# Type Assertion hell

I'm trying to get some data that's fairly deep in some json, and ended up doing a lot of awkward feeling type assertions:

```
func (game Game) checkGameDocInChanges(changes Changes) bool {
        foundGameDoc := false
        changeResultsRaw := changes["results"]
        changeResults := changeResultsRaw.([]interface{})
        for _, changeResultRaw := range changeResults {
                changeResult := changeResultRaw.(map[string]interface{})
                docIdRaw := changeResult["id"]
                docId := docIdRaw.(string)
                if strings.Contains(docId, GAME_DOC_ID) {
                        foundGameDoc = true
        		}
        }
        return foundGameDoc
}
```

there must be a better way?

Also I didn't get why this didn't work:

```
type ChangeItem map[string]interface{}
...
changeResult := changeResultRaw.(ChangeItem)
```

to make it work I had to change it to:

```
changeResult := changeResultRaw.(map[string]interface{})
```

# Getting unexpected float64 back from JSON, had to do awkward type conversions

```
func (game Game) isOurTurn(gameDoc Document) bool {
        activeTeamRaw := gameDoc["activeTeam"]
        activeTeam := int(activeTeamRaw.(float64))
        return activeTeam == game.ourTeamId
}
```

Json snippet:

```
{"_id":"game:checkers","activeTeam":0}
```

# Can't check for nil

I have these structs:

```
type Game struct {
    gameState            GameState
}

type GameState struct {
   ...
}
```

and in a loop, I set the gameState field of the Game object to value.  I'm trying to detect if it's the first pass through the loop with this:

```
isFirstGame := (game.gameState == nil)
```

but I get the error `cannot convert nil to type GameState`
