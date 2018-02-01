# This dockerfile creates a container with all tools required to access and
# manage intances and containers at the google cloud platform with
# ansible and terraform
#
# Author Daniel Porto

FROM google/cloud-sdk:alpine
#-----------------------------------------------------------------------------
# install dependencies
#-----------------------------------------------------------------------------
# install tools for managing ppa repositories
RUN apk update \
    # depends on unzip curl git already present
    && apk add tmux \
                # sudo is required to copy files from volumes into the container
                sudo \
                # perl and ncurses are required for vim
                vim perl ncurses\
    && rm -rf /var/cache/apk/*


#-----------------------------------------------------------------------------
# install ansible - future
#-----------------------------------------------------------------------------
# RUN apk update \
#     && apk add ansible \
#     && rm -rf /var/cache/apk/*


#-----------------------------------------------------------------------------
# install terraform
#-----------------------------------------------------------------------------
RUN curl -O https://releases.hashicorp.com/terraform/0.11.2/terraform_0.11.2_linux_amd64.zip \
    && unzip terraform_0.11.2_linux_amd64.zip -d /usr/local/bin \
    && rm terraform_0.11.2_linux_amd64.zip 
# some extra packages for drawing the infrastructure
# RUN apk update \
#     # depends on unzip curl git already present
#     && apk add graphviz \
#     && rm -rf /var/cache/apk/*



#-----------------------------------------------------------------------------
# install locales, required for scripts
#-----------------------------------------------------------------------------
# some scripts require locale to be properly set    
ENV LANG en_US.utf8

  
#-----------------------------------------------------------------------------
# install zshell and dotfiles
#-----------------------------------------------------------------------------
# install zsh with a some plugins
RUN apk update \
    # depends on unzip curl git already present
    && apk add zsh \
    #&& chsh -s $(which zsh) \
    && rm -rf /var/cache/apk/*
ENV SHELL /bin/zsh

#-----------------------------------------------------------------------------
# configuring cloud environment - depends on zshell above
#-----------------------------------------------------------------------------
# add the content into the container.
ADD . /gcloud
WORKDIR /gcloud
RUN chmod +x /gcloud/*.sh

# some instances does not allow root login, thus start with a regular one.
RUN adduser -s /bin/sh -D -h /home/cloudusr cloudusr \
    && echo "cloudusr ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && chown -R cloudusr.cloudusr /gcloud 


# switch user to install zsh with a some plugins
USER cloudusr
ENV HOME /home/cloudusr
ENV PATH =PATH=/google-cloud-sdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN /bin/zsh -ic 'git clone https://github.com/danielporto/zsh-dotfiles.git $HOME/dotfiles && $HOME/dotfiles/install' \
    # install zsh plugins
    && export TERM=dumb && /bin/zsh -ic 'exit' < /dev/null \
    # cloud environment variables
    && echo "source /gcloud/envs.sh" >> $HOME/dotfiles/zshrc \
    && echo "source /gcloud/load-credentials.sh" >> $HOME/dotfiles/zshrc 


#-----------------------------------------------------------------------------
# default terminal configuration and customization
#-----------------------------------------------------------------------------
# open a tmux terminal or reattach whenever the container starts
CMD ["tmux", "new-session", "-A", "-s main"] 
