FROM nvidia/cuda:10.2-base-ubuntu18.04

# Install some basic utilities
RUN apt-get update && apt-get install -y \
    autojump \
    bzip2 \
    ca-certificates \
    curl \
    direnv \
    git \
    libx11-6 \
    rsync \
    sudo \
    task-spooler \
    tmux \
    vim \
    yadm \
    zsh \
  && rm -rf /var/lib/apt/lists/*
RUN apt-get autoremove -y \
  && apt-get clean \
  && rm -rf /usr/local/src/*

# Create a non-root user and switch to it
RUN mkdir /app
RUN adduser --disabled-password --gecos '' --shell /usr/bin/zsh user \
  && chown -R user:user /app
RUN echo "user ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/90-user
USER user

# All users can use /home/user as their home directory
ENV HOME=/home/user
ENV PATH=$PATH:/home/user/local/anaconda3/bin
RUN chmod 777 /home/user
WORKDIR /home/user
RUN mkdir ./local

RUN yadm clone https://gitlab.com/akirasosa/dotfiles.git
RUN curl -sL git.io/antibody | sh -s
RUN ./bin/antibody bundle < ~/.zsh_plugins.txt
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
  && ~/.fzf/install --no-key-bindings --no-completion --no-update-rc
RUN curl -sS https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-301.0.0-linux-x86_64.tar.gz > google-cloud-sdk.tar.gz \
  && tar xzf google-cloud-sdk.tar.gz \
  && mv google-cloud-sdk ~/local/ \
  && rm -rf google-cloud-sdk.tar.gz
RUN curl -sS https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh > ~/anaconda.sh \
  && /bin/bash ~/anaconda.sh -b -p ~/local/anaconda3 \
  && rm -rf ~/anaconda.sh \
  && conda update conda -y \
  && conda clean -i -t -y
RUN conda install -c conda-forge -y \
  python=3.8 \
  go-ghq \
  jupyter_contrib_nbextensions \
  && conda clean -i -t -y
RUN jupyter notebook --generate-config \
  && jupyter contrib nbextension install --user \
  && mkdir -p $(jupyter --data-dir)/nbextensions \
  && cd $(jupyter --data-dir)/nbextensions \
  && git clone https://github.com/lambdalisue/jupyter-vim-binding vim_binding \
  && chmod -R go-w vim_binding \
  && jupyter nbextension enable vim_binding/vim_binding

WORKDIR /app

CMD ["/usr/bin/zsh", "-l"]
