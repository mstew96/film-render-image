# procedure-film kit v2.0: the FILM IMAGE for RunPod pods (Blender 4.5.15 LTS + ffmpeg + our Python deps, ready to render).
# Pods on this image start in ~2 min instead of a ~12-min install, in any data centre.
# Built by GitHub Actions (kit/cloud/image/build-film-image.yml) and stored on GitHub's image storage:
#   ghcr.io/<github user>/film-render:4.5.15-k2.0
# Base = the RunPod image we already use (cached on most RunPod hosts, so only our ~0.5 GB layer is pulled). It keeps
# RunPod's start script (sshd from PUBLIC_KEY, runpodctl), which the kit's ssh + watchdog rely on.
# Bump the tag (k2.1 ...) whenever this file changes; never re-use a tag.
FROM runpod/pytorch:1.0.2-cu1281-torch280-ubuntu2404

ARG BLENDER_VER=4.5.15
ARG BLENDER_SHA256=0d2b8bb2efe97e6c8eb57de6b7322f8800e1984e3125b60decca5f6771e4773e
ARG BLENDER_MIRROR=https://mirrors.dotsrc.org/blender

# Libraries Blender needs headless (EGL for Workbench rough cuts), ffmpeg, cairo for the storyboard sheets
RUN apt-get update -qq && apt-get install -y -qq --no-install-recommends \
      libxi6 libxxf86vm1 libxfixes3 libxrender1 libgl1 libxkbcommon0 libsm6 libice6 libegl1 libcairo2 \
      ffmpeg rsync xz-utils curl ca-certificates \
 && rm -rf /var/lib/apt/lists/*

# Blender, checked against the official sha256 (fails the build if it does not match)
RUN cd /tmp && F=blender-${BLENDER_VER}-linux-x64.tar.xz \
 && (curl -fsSL --retry 5 -o $F ${BLENDER_MIRROR}/release/Blender4.5/$F \
     || curl -fsSL --retry 5 -o $F https://download.blender.org/release/Blender4.5/$F) \
 && echo "${BLENDER_SHA256}  $F" | sha256sum -c - \
 && tar xf $F && mv blender-${BLENDER_VER}-linux-x64 /opt/blender && rm -f $F \
 && /opt/blender/blender --version | head -1

RUN pip install -q --no-cache-dir --break-system-packages pillow numpy cairosvg \
 && echo "blender ${BLENDER_VER}" > /opt/film-image-ready

LABEL org.opencontainers.image.description="procedure-film render image: Blender ${BLENDER_VER} LTS + ffmpeg (kit v2.0)"
# No CMD/ENTRYPOINT change: RunPod's own start script (sshd, runpodctl) stays in charge.
