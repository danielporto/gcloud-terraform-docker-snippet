# This dockerfile creates a container with all tools required to access and
# manage intances and containers at the google cloud platform with
# ansible and terraform
#
# Author Daniel Porto

FROM ubuntu:artful
#-----------------------------------------------------------------------------
# install dependencies
#-----------------------------------------------------------------------------
# install tools for managing ppa repositories
RUN apt update \
    && apt -y install   software-properties-common \
                        unzip \
                        vim \
                        curl \
                        tmux \
                        git \
                        sudo \
    && rm -rf /var/lib/apt/lists/* 

#-----------------------------------------------------------------------------
# install google cloud platform and kubernetes client
#-----------------------------------------------------------------------------
    # Create an environment variable for the correct distribution
    RUN export CLOUD_SDK_REPO="cloud-sdk-$(lsb_release -c -s)" \
    # Add the Cloud SDK distribution URI as a package source
    && echo "deb http://packages.cloud.google.com/apt $CLOUD_SDK_REPO main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list \
    # Import the Google Cloud Platform public key
    && curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - \
    # add google cloud sdk
    # && apt install -y --allow-unauthenticated google-cloud-sdk \
    && apt update \
    && apt install -y   google-cloud-sdk \
                        # kubectl \
    && rm -rf /var/lib/apt/lists/* 

#-----------------------------------------------------------------------------
# install ansible
#-----------------------------------------------------------------------------
# add extra repositories
RUN apt-add-repository -y ppa:ansible/ansible \
    && apt update  \
    # add deployment management tool
    && apt install -y ansible \
    && rm -rf /var/lib/apt/lists/* 

#-----------------------------------------------------------------------------
# install terraform
#-----------------------------------------------------------------------------
RUN curl -O https://releases.hashicorp.com/terraform/0.11.2/terraform_0.11.2_linux_amd64.zip \
    && unzip terraform_0.11.2_linux_amd64.zip -d /usr/local/bin \
    && rm terraform_0.11.2_linux_amd64.zip 
# some extra packages for drawing the infrastructure
# RUN  apt update  \
# # add graph builder tool for terraform
#     && apt install -y graphviz \
#     && rm -rf /var/lib/apt/lists/* 


#-----------------------------------------------------------------------------
# install locales, required for scripts
#-----------------------------------------------------------------------------
# some scripts require locale to be properly set    
RUN apt-get update && apt-get install -y locales && rm -rf /var/lib/apt/lists/* \
    && localedef -i en_US -c -f UTF-8 -A /usr/share/locale/locale.alias en_US.UTF-8
ENV LANG en_US.utf8

  
#-----------------------------------------------------------------------------
# install zshell and dotfiles
#-----------------------------------------------------------------------------
# install zsh with a some plugins
RUN apt update && apt install -y zsh && rm -rf /var/lib/apt/lists/* \
    # && git clone https://github.com/danielporto/zsh-dotfiles.git $HOME/dotfiles && $HOME/dotfiles/install \
    # # define zsh as default shell
    # && chsh -s $(which zsh) \
    # # install zsh plugins
    # && export TERM=dumb && /usr/bin/zsh -ic 'exit' < /dev/null
    && chsh -s $(which zsh)

#-----------------------------------------------------------------------------
# configuring cloud environment - depends on zshell above
#-----------------------------------------------------------------------------
# add the content into the container.
ADD . /gcloud
WORKDIR /gcloud
RUN chmod +x /gcloud/*.sh
# # cloud environment variables
# RUN  echo "source /gcloud/envs.sh" >> $HOME/dotfiles/zshrc \
#     && echo "source /gcloud/load-credentials.sh" >> $HOME/dotfiles/zshrc 


# some instances does not allow root login, thus start with a regular one.
RUN useradd -c 'cloud user' -m -d /home/cloudusr -s /usr/bin/zsh cloudusr \
    && echo "cloudusr ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && chown -R cloudusr.cloudusr /gcloud 


# switch user to install zsh with a some plugins
USER cloudusr
ENV HOME /home/cloudusr
RUN git clone https://github.com/danielporto/zsh-dotfiles.git $HOME/dotfiles && $HOME/dotfiles/install \
    # install zsh plugins
    && export TERM=dumb && /usr/bin/zsh -ic 'exit' < /dev/null \
    # cloud environment variables
    && echo "source /gcloud/envs.sh" >> $HOME/dotfiles/zshrc \
    && echo "source /gcloud/load-credentials.sh" >> $HOME/dotfiles/zshrc 


#-----------------------------------------------------------------------------
# default terminal configuration and customization
#-----------------------------------------------------------------------------
# open a tmux terminal or reattach whenever the container starts
CMD ["tmux", "new-session", "-A", "-s main"] 
