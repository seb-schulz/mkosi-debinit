# mkosi-debinit

It builds a bootable initramfs for Linux kernel with mkosi on Debian.
With the approach of building an image with mkosi, initramfs should become more reproducable and better testable.

## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
- [Contributing](#contributing)
- [License](#license)

## Installation

Add public key and create a source list file for `apt`. For example:

```shell
curl -fsSL https://seb-schulz.github.io/mkosi-debinit/public.gpg | sudo tee /etc/apt/keyrings/mkosi-debinit.gpg > /dev/null
echo "deb [signed-by=/etc/apt/keyrings/mkosi-debinit.gpg] https://seb-schulz.github.io/mkosi-debinit testing main" | sudo tee /etc/apt/sources.list.d/mkosi-debinit.list
```

Run `sudo apt update` afterwards to fetch all relevant information about this repository.
Replace your initramfs build with `sudo apt install mkosi-debinit`.

## Usage

Whenever an update of a kernel is running, hooks within the directories of `/etc/kernel/postinst.d` and `/etc/kernel/postrm.d` are generating a working initramfs.

In case an individual initramfs should be created, `update-mkosi-debinit` creates it.
For more information checkout [the manpage](update-mkosi-debinit.md).

## Contributing

When contributing to this repository, please first discuss the change you wish to make via issue,
email, or any other method with the owners of this repository before making a change.

<!-- Please note we have a code of conduct, please follow it in all your interactions with the project. -->

### Submitting a pull request

Thanks in advance for your contribution.

1. Follow the usual git workflow for submitting a pull request:
   - Fork and clone the project.
   - Create a new branch from main (e.g. `features/my-new-feature` or `issue/123-my-bugfix`).
   - Add your changes.
   - Take notes of relevant changes on top of the [changelog](debian/changelog)
   - Commit your changes and create a pull request.
2. If your change include drastic or low level changes please discuss them to make sure they will be accepted and what the impact will be.
3. If your change is based on existing functionality, please consider refactoring first. Pull requests that duplicate code will not make it in very quick, if at all.
4. Do not include changes that are not related to the issue at hand.
5. Follow the same coding style with regards to spaces, semicolons, variable naming etc. This project is using [prettier](https://prettier.io/) for code formatting.

## Links

- <https://www.debian.org/doc/debian-policy/index.html>
- <https://github.com/systemd/mkosi/>
