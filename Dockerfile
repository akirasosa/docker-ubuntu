FROM nvidia/cuda:10.2-base-ubuntu18.04

# Install some basic utilities
RUN apt-get update && apt-get install -y \
    curl \
    ca-certificates \
    sudo \
    git \
    bzip2 \
    libx11-6 \
    yadm \
    zsh \
    tmux \
    vim \
    autojump \
    direnv \
 && rm -rf /var/lib/apt/lists/*

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
RUN ./bin/antibody bundle
RUN curl -s https://dl.google.com/go/go1.14.6.linux-amd64.tar.gz > ~/go.tar.gz \
  && tar xzf ~/go.tar.gz -C ./local \
  && rm -rf ~/go.tar.gz
RUN ~/local/go/bin/go get github.com/x-motemen/ghq
RUN git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf \
  && ~/.fzf/install --no-key-bindings --no-completion --no-update-rc
RUN curl -s https://repo.anaconda.com/archive/Anaconda3-2020.07-Linux-x86_64.sh > ~/anaconda.sh \
  && /bin/bash ~/anaconda.sh -b -p ~/local/anaconda3 \
  && rm -rf ~/anaconda.sh
RUN curl -s https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-301.0.0-linux-x86_64.tar.gz > google-cloud-sdk.tar.gz \
  && tar xzf google-cloud-sdk.tar.gz \
  && mv google-cloud-sdk ~/local/ \
  && rm -rf google-cloud-sdk.tar.gz
RUN jupyter notebook --generate-config \
	&& pip install jupyter_contrib_nbextensions \
	&& jupyter contrib nbextension install --user \
	&& mkdir -p $(jupyter --data-dir)/nbextensions \
	&& cd $(jupyter --data-dir)/nbextensions \
	&& git clone https://github.com/lambdalisue/jupyter-vim-binding vim_binding \
	&& chmod -R go-w vim_binding \
	&& jupyter nbextension enable vim_binding/vim_binding

WORKDIR /app

CMD ["/usr/bin/zsh","-l"]
