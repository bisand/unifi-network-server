#!/usr/bin/env python3
"""Pin an image reference in a Kubernetes manifest.

Used by .github/workflows/docker-publish.yml to write the freshly published
image into the GitOps repo. That commit is the deploy: Flux reconciles
it, so this rewrite has to be exact or it silently deploys the wrong thing.

Rewrites the single `image:` line naming the given repository, whatever it is
currently pinned to (tag, digest, or both), and fails loudly on anything other
than exactly one match — a renamed or restructured manifest must break the
build, not quietly no-op.

Usage: pin-image.py <manifest> <image-repo> <full-ref>
"""

import re
import sys


def main(argv):
    if len(argv) != 4:
        sys.exit(f"usage: {argv[0]} <manifest> <image-repo> <full-ref>")

    path, image, ref = argv[1], argv[2], argv[3]

    if not ref.startswith(image + ":"):
        sys.exit(f"refusing to write '{ref}': it is not a reference to {image}")

    with open(path) as fh:
        src = fh.read()

    # The repo name, optionally followed by :tag, @digest, or :tag@digest.
    pattern = re.compile(
        r"^(\s*image:\s*)" + re.escape(image) + r"(?:[:@][^\s]*)?[ \t]*$",
        re.MULTILINE,
    )
    out, count = pattern.subn(lambda m: m.group(1) + ref, src)

    if count != 1:
        sys.exit(
            f"expected exactly one image line for {image} in {path}, found {count}. "
            "The manifest moved or was restructured — fix the workflow rather than "
            "letting a deploy silently do nothing."
        )

    with open(path, "w") as fh:
        fh.write(out)

    print(f"pinned {ref}")


if __name__ == "__main__":
    main(sys.argv)
