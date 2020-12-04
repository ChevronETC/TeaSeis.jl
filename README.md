# TeaSeis

| **Documentation** | **Action Statuses** |
|:---:|:---:|
| [![][docs-dev-img]][docs-dev-url] [![][docs-stable-img]][docs-stable-url] | [![][doc-build-status-img]][doc-build-status-url] [![][build-status-img]][build-status-url] [![][code-coverage-img]][code-coverage-results] |

TeaSeis.jl is a Julia library for reading and writing JavaSeis files (The name `TeaSeis.jl` was chosen instead of `JavaSeis.jl` due to potential trademark issues).  The JavaSeis file format is used in various software projects including [SeisSpace](https://www.landmark.solutions/seisspace-promax).  The original library is written in [Java](http://sourceforge.net/projects/javaseis).  There are also [C++](http://www.jseisio.com>C++) and [Python](https://github.com/asbjorn/pyjavaseis) implementations available.  Similar to the C++ library, TeaSeis.jl is a stripped down version of the original Java library.  In particular, the intent is to only supply methods for reading and writing from and to JavaSeis files.

[docs-dev-img]: https://img.shields.io/badge/docs-dev-blue.svg
[docs-dev-url]: https://chevronetc.github.io/TeaSeis.jl/dev/

[docs-stable-img]: https://img.shields.io/badge/docs-stable-blue.svg
[docs-stable-url]: https://ChevronETC.github.io/TeaSeis.jl/stable

[doc-build-status-img]: https://github.com/ChevronETC/TeaSeis.jl/workflows/Documentation/badge.svg
[doc-build-status-url]: https://github.com/ChevronETC/TeaSeis.jl/actions?query=workflow%3ADocumentation

[build-status-img]: https://github.com/ChevronETC/TeaSeis.jl/workflows/Tests/badge.svg
[build-status-url]: https://github.com/ChevronETC/TeaSeis.jl/actions?query=workflow%3A"Tests"

[code-coverage-img]: https://codecov.io/gh/ChevronETC/TeaSeis.jl/branch/master/graph/badge.svg
[code-coverage-results]: https://codecov.io/gh/ChevronETC/TeaSeis.jl
