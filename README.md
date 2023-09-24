# davidcel.is

This is the code for my personal website and blog, which you can visit at [davidcel.is](https://davidcel.is/)! It's a Ruby on Rails application that's still under active development. Right now, you can read articles and notes that I write/post, see a (somewhat) curated set of my photos as I take them, or just read more about me. If you don't want to spend a bunch of time on my website proper, I guess you can also [subscribe via RSS](https://davidcel.is/feeds/main) or read my posts on other social media websites. Currently, I syndicate to [Mastodon](https://xoxo.zone/@davidcelis) and [Bluesky](https://bsky.app/profile/davidcel.is).

For myself, there's an admin to manage my posts and photos, although I don't sync edits to Mastodon or Bluesky yet. I also set up a post composer for myself using [ink-mde](https://github.com/davidmyersdev/ink-mde) so I can just pull out my phone, type up my short thoughts, and hit "Send", just like I would have on Twitter (RIP). Both the admin and the post composer are locked behind an OAuth handshake with GitHub.

As mentioned before, I hope to continue actively maintaining this website and adding to it. For example, some things I'd love to implement are:

- [ ] Serving WebP images to browsers that support it (while still storing the originals)
  - [ ] WebP images should be what's used to syndicate to external services, especially since Bluesky has such a small file size limit
- [ ] Drafts (especially for articles) so I can start writing something and finish later
- [ ] Show my most recent check-in (or location in general) in the sidebar
- [ ] More types of posts!
  - [ ] Reposts
  - [ ] Replies
- [ ] Syncing check-ins to a third party service. I used Swarm for years, but gave up on it during lockdown. I've been trying Gowalla instead since it was re-released, but their future is uncertain. I might just go back to Swarm and consider the Gowalla check-ins lost 😅

## License

This code, my website, and all of the content therein are licensed under the [Creative Commons Attribution 4.0 International License](https://creativecommons.org/licenses/by/4.0/). What does this mean in practice? As long as you provide the proper attribution to me, you're free to fork this repository and modify it to develop your own website, and you're free to share or even adapt the articles or other posts that I've written, even for commercial purposes. Just give me appropriate credit, provide a link to my license, and indicate whether or not you made changes.

The design is a modified version of [Tailwind's Transmit UI template](https://tailwindui.com/templates/transmit), but the code was written by me, and it was largely written _for_ me. There's a lot of hard-coded personal text, and there's currently no theming to make it easy to customize its appearance. You're free to use this code to develop your own website, but you'll want to do proper personalization to make it yours!
