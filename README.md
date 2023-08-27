# ACRL build-scripts

Build scripts for Applied Computing Research Labs projects

## To use:

Add this repo as a submodule in your repo:

```
git submodule add https://github.com/acrlabs/build-scripts build
```

Create a `Makefile` in your project defining a list of build artifacts in the `ARTIFACTS` variable;
Then, include `build/base.mk, and then define a build target for `$(ARTIFACTS)`.  You should also define build targets
for `test`, `lint`, and `cover` (these can be empty if you don't want to do anything here).  Note the ordering is
important here.

You can reference `$(BUILD_DIR)` and `$(K8S_MANIFEST_DIR)` in your build targets.

The default build target is `build image run` which builds your artifacts, creates Docker images for them, and deploys
them to your Kubernetes cluster.  You can also run `make verify` to run `lint test cover`.

## Example project makefile:

```
ARTIFACTS=binary1 binary2

include build/base.mk

$(ARTIFACTS):
	CGO_ENABLED=0 go build -trimpath -o $(BUILD_DIR)/$@ ./cmd/$@

lint:
	golangci-lint run

cover:
	go-carpet -summary
```

---

<p style="text-align: center" xmlns:dct="http://purl.org/dc/terms/" xmlns:vcard="http://www.w3.org/2001/vcard-rdf/3.0#">
  <a rel="license"
     href="http://creativecommons.org/publicdomain/zero/1.0/">
    <img src="http://i.creativecommons.org/p/zero/1.0/88x31.png" style="border-style: none;" alt="CC0" />
  </a>
  <br />
  To the extent possible under law,
  <a rel="dct:publisher"
     href="https://appliedcomputing.io">
    <span property="dct:title">Applied Computing Research Labs, LLC</span></a>
  has waived all copyright and related or neighboring rights to
  this work.
This work is published from:
<span property="vcard:Country" datatype="dct:ISO3166"
      content="US" about="https://appliedcomputing.io">
  United States</span>.
</p>
