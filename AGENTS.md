# Seven Story Rabbit Hole (Octopress blog)

Live at https://tleyden.github.io. This is an old Octopress 2 / Jekyll 0.12 blog (Ruby, ~2013).
All Ruby tooling runs **inside Docker**. Never install gems, Ruby, or Python on the host.

## No AI writing

**Never write or rewrite blog prose** (posts, About text, titles, subtitles) unless the user
explicitly asks for that specific text to be written. The user writes the words; agents handle
tooling, formatting, front matter, builds, and deploys. When the user supplies text, use it
verbatim. Don't polish it, expand it, add sections, add links, or fix wording without asking.
If something seems to need prose, ask the user for it instead of drafting it.

## Branches (important)

| Branch   | Contents                                  | How it gets updated                    |
|----------|-------------------------------------------|----------------------------------------|
| `source` | Markdown posts, theme, Rakefile, config   | Normal `git commit` + `git push origin source` |
| `master` | **Generated** static HTML served by GitHub Pages | Only via `./blog.sh deploy`. Never edit by hand. |

Work on the `source` branch. `master` is a build artifact.

## Commands (`./blog.sh`)

```
./blog.sh image             # (re)build the octopress-blog Docker image (auto-built on first use)
./blog.sh new "Post title"  # create source/_posts/YYYY-MM-DD-post-title.markdown
./blog.sh preview           # live-reloading preview at http://localhost:4001 (Ctrl-C to stop)
./blog.sh generate          # build the site into public/
./blog.sh deploy            # generate, then commit public/ to master via _deploy/ and push
./blog.sh shell             # bash inside the container (run `bundle exec rake ...` yourself)
```

How it works: `Dockerfile` builds an image with Ruby 2.3, Python 2 (for pygments.rb), and the
bundled gems. `blog.sh` bind-mounts the repo at `/blog` and runs `bundle exec rake ...`.
Git operations (including deploy pushes) run on the **host**, so they use your normal GitHub
credentials. The container has no git credentials.

`_deploy/` (gitignored) is a local clone of the `master` branch that `deploy` creates on first use.
`public/` (gitignored) is the generated site.

## Writing and publishing a post

1. `git checkout source && git pull`
2. `./blog.sh new "My Title"`, then edit the new file in `source/_posts/`.
   Front matter: `layout: post`, `title`, `date`, `comments: true`, `categories: a b c`
   (space-separated, **no commas**; a trailing comma creates a bogus category like `gpu,`).
3. `./blog.sh preview` and check http://localhost:4001
4. Commit and push the source: `git add -A && git commit -m "..." && git push origin source`
5. Publish: `./blog.sh deploy`

Always do step 4 as well as step 5. If you deploy without committing to `source`, the change exists
only in the generated HTML and will be lost on the next deploy. (This happened once: the
"Continued .." section of the 2022-10-19 Autoware post had to be recovered from `master`.)

## Markdown gotchas

- Renderer is rdiscount (old). For code, prefer Octopress's fenced blocks with a blank line before
  them: a ```` ``` ```` fence directly after a paragraph line can render as literal backticks.
  Check in preview.
- Octopress tags also work: `{% codeblock lang:go %} ... {% endcodeblock %}`, `{% img url %}`.
- Images go in `source/images/` and are referenced as `/images/foo.png`.
- Drafts that should not be published live in `drafts/`, outside `source/_posts`.

## Why these versions

The Gemfile.lock pins pygments.rb 0.3.4, which requires yajl-ruby 1.1.0. That gem uses
`rb_cFixnum`, removed in Ruby 2.4, so the image must stay on Ruby 2.3. `ruby:2.3-stretch` has a
native arm64 build, which avoids needing amd64 emulation on Apple Silicon. Container
`TZ=America/Los_Angeles` keeps post timestamps identical to past builds.
