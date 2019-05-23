# my-website

Sources for my (mainly) Hugo-based website.

# Rust posts - next

* Logging setup
* Serialization results - JSON/TOML equivalence
* How to set RUST_BACKTRACE in Linux and Windows (see Release builds post)
* Ownership model

# Rust posts
* Builder pattern
* Ergonomic hashmap keys - implementing Borrow. Use my FileInfo struct as an example
* Rustfmt
  - disable_all_formatting = true (from ripgrep)
* Cargo tools
  - cargo install --force --path .
* Cargo tips and tricks
  - bin programs (p174)
  - documentation generation (p181)
* Porting C code base
* Case-insensitive HashMaps and string comparisons
* Combinator APIs for Option and Result (F# railway programming?)
* Modules
  - pub use x::y::z; use brings into scope in this module, and pub makes it visible outside
    preludes are written like this
  - what do all the pub(xxx) things mean
* New types
* Enums - using strum and smart_default
* More Unicode - including crow's foot symbols, links to Wikipedia pages
* LINQ to Rust - Port content from 'rsforcs' and delete that repo
* All about comments
    - Doc comments, module level comments
* Various other C# techniques
    - embedded resources
    - extension methods (can also do static extensions with traits in Rust)
    - null, nullable types
    - conditional compilation
    - dates and times
    - XML
    - Files, Paths and IO (Stream)
    - Serialization, esp. JSON
    - the major collections (List->Vec, Dictionary->HashMap, HashSet)
    - starting processes
    - command line arguments
    - text files
    - Strings, formatting and parsing cheatsheet
    - Common NuGet packages vs Common Crates
    - Testing
    - Console IO

# Other posts
* REST API URL forms
* Cheatsheet for find
* Cheatsheet for bash
* Cheatsheet for PowerShell


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

