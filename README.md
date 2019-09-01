# windows-dind-build-image

While there is no true windows DIND, this image connecs to the host's docker tcp socket and uses it to emulate the DIND process. This is pretty much a hack so use it in your own accord.

This docker image is a DIND made to be used as a build slave to create other docker images programatically by an orchestrator. E.g. jenkins, GoCd, etc.

As the container orchestration world rises there is a need to create containerized applications on the fly, this image eases this process.

## Usage

The orchestrator instance creates and connects to this instance via SSH over user/password combination.

### User/Password:

The image is already configured to use user and passord as follows:

```
usr: root
psw: lJe2u2P+iMk0lyCNHsEM39Sxe0+0R+x6Urkdhno5ffw=
```
