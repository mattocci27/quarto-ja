
FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8

RUN apt-get update && apt-get install -y --no-install-recommends \
    wget \
    curl \
    xz-utils \
    ca-certificates \
    perl \
    fontconfig \
    pandoc \
    pdftk \
    make \
    fonts-roboto \
    && rm -rf /var/lib/apt/lists/*

# Copy fonts staged by the YAML step and rebuild the OS font cache
COPY temp_fonts /usr/share/fonts/mac

RUN fc-cache -fv

# --- Quarto: auto-detect architecture ---
ARG QUARTO_VERSION=1.9.38
RUN Q_ARCH="$(dpkg --print-architecture)" \
    && if [ "${Q_ARCH}" = "arm64" ]; then Q_ARCH="arm64"; else Q_ARCH="amd64"; fi \
    && curl -fL -o /tmp/quarto.deb "https://github.com/quarto-dev/quarto-cli/releases/download/v${QUARTO_VERSION}/quarto-${QUARTO_VERSION}-linux-${Q_ARCH}.deb" \
    && apt-get update \
    && apt-get install -y /tmp/quarto.deb \
    && rm /tmp/quarto.deb \
    && rm -rf /var/lib/apt/lists/*

# --- TinyTeX: install and resolve PATH automatically ---
RUN curl -fsSL https://raw.githubusercontent.com/rstudio/tinytex/main/tools/install-bin-unix.sh | sh \
    # Symlink so PATH works on any architecture (aarch64 / x86_64)
    && ln -s /root/.TinyTeX/bin/*-linux /root/.TinyTeX/bin/active

ENV PATH="/root/.TinyTeX/bin/active:${PATH}"

# --- tlmgr: curated package list with duplicates and unnecessary fonts removed ---
RUN tlmgr update --self \
    && tlmgr install \
      # Japanese language and encoding essentials
      zxjatype \
      xecjk \
      bxbase \
      etoolbox \
      # Table extensions (for gt / kableExtra)
      booktabs \
      caption \
      colortbl \
      multirow \
      makecell \
      threeparttable \
      threeparttablex \
      # Quotes, layout, and decoration
      csquotes \
      environ \
      koma-script \
      pdflscape \
      pgf \
      tcolorbox \
      listings \
      fvextra \
      # Academic writing (formatting, line numbers, cross-references)
      microtype \
      setspace \
      lineno \
      titlesec \
      # Symbols, decoration, and other utilities
      academicons \
      fontawesome5 \
      fancyhdr \
      mdframed \
      needspace \
      parskip \
      sectsty \
      titling \
      ulem \
      wrapfig \
      xurl

WORKDIR /docs
