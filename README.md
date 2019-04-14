# my-website




Sources for my (mainly) Hugo-based website.

# Rust posts
* Logging setup
* Iterate, don't mutate - patterns for fixing
* Porting C code base
* Ergonomic hashmap keys - implementing Borrow. Use my FileInfo struct as an example
* Cargo tools
  cargo install --force --path .
* Case-insensitive HashMaps and string comparisons
* Getting a mutable reference to something in a deep structure
* REST API URL forms
* Cheatsheet for find
* Cheatsheet for bash
* Cheatsheet for PowerShell
* Release mode builds
  RUSTFLAGS="-C target-cpu=native" cargo build --release --features 'simd-accel'
  [profile.release]
    debug = 1 (from ripgrep)
* Rustfmt
  disable_all_formatting = true (from ripgrep)

# TODO
* [ ] RSS
* [ ] Get mdbook 'Run Rust' working
    * [ ] Copy to clipboard
    * [ ] Run this code - this is the Rust Playpen
    * [ ] Integrate the Ace Editor
    * [ ] We need to know how to make our own shortcode? And perhaps how to integrate
          with highlight.js to ensure themes match.

* [ ] Port ConfigZilla pages, including GA
* [ ] Rebuild my gitcheatsheet?
* [ ] Navigation issues
    * [ ] Clicking Phil's Blog should take you to the 'posts' page
    * [ ] The LHS should have explicit links for the blog, rust-for-cs, and Linux cheats?
* [ ] Layout issues
    * [ ] Make main font smaller?
    * [ ] Decrease line spacing?
    * [ ] Tables need to stand out more, especially the headers
    * [ ] Multi-header tables - how to?

https://github.com/integer32llc/rust-playground/
https://ace.c9.io/
https://github.com/rust-lang-nursery/mdBook/tree/42b87e0fbc6815ae2177a5fc4838dad11a33fe4f/src/theme


Can do it with a link:

<a href='https://play.integer32.com/?code=fn main() { println!("hello world!"); }'>Play</a>




To run code (and make it editable) the code is in mdbook
book.js contains the code to add the COPY and RUN buttons to certain Rust code blocks.
playpen_editor contains the 'ace' editor which is used to make the code editable.

The HTML looks like this:


<pre>
    <pre class="playpen">
        <div class="buttons">
            <button class="fa fa-copy clip-button" title="Copy to clipboard" aria-label="Copy to clipboard"><i class="tooltiptext"></i></button>
            <button class="fa fa-play play-button" title="Run this code" aria-label="Run this code" hidden=""></button>
        </div>
        <code class="language-rust hljs">
            <span class="hljs-function"><span class="hljs-keyword">fn</span> <span class="hljs-title">main</span></span>() {
    <span class="hljs-built_in">println!</span>(<span class="hljs-string">"Hello, world!"</span>);

    another_function();
}

<span class="hljs-function"><span class="hljs-keyword">fn</span> <span class="hljs-title">another_function</span></span>() {
    <span class="hljs-built_in">println!</span>(<span class="hljs-string">"Another function."</span>);
}

        </code>
        <code class="result hljs language-bash">
            Hello, world!<br>Another function.<br>
        </code>
    </pre>
</pre>



There is also a 'show hidden lines' icon in some code blocks.
I cannot find any editable code blocks.

