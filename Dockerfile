# This dockerfile creates a container with all tools required to access and
# manage intances and containers at the google cloud platform with
# ansible and terraform
#
# Author Daniel Porto

FROM google/cloud-sdk:alpine
LABEL maintainer="daniel.porto@gmail.com"
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
RUN apk update \
    && apk add 'ansible<2.4.2' \
    && rm -rf /var/cache/apk/* 
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
COPY . /gcloud
WORKDIR /gcloud
# add support for terraform dynamic inventory
ADD https://github.com/nbering/terraform-inventory/releases/download/v1.0.1/terraform.py /usr/local/bin/
ADD https://github.com/nbering/terraform-provider-ansible/releases/download/v0.0.3/terraform-provider-ansible-linux_amd64.zip .
RUN unzip terraform-provider-ansible-linux_amd64.zip && rm -f terraform-provider-ansible-linux_amd64.zip \
    && mkdir -p .terraform/plugins \
    && mv linux_amd64 .terraform/plugins \
    && chmod +x /gcloud/*.sh && chmod o+rx /usr/local/bin/terraform.py 

# GCP instances does not allow root login, thus start with a regular one.
RUN adduser -s /bin/sh -D -h /home/cloudusr cloudusr \
    && echo "cloudusr ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers \
    && chown -R cloudusr.cloudusr /gcloud 


# switch user to install zsh with a some plugins
USER cloudusr
ENV HOME /home/cloudusr
ENV PATH /google-cloud-sdk/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

RUN /bin/zsh -ic 'git clone https://github.com/danielporto/zsh-dotfiles.git $HOME/dotfiles && $HOME/dotfiles/install' \
    # cloud environment variables
    && echo "source /gcloud/envs.sh" >> $HOME/dotfiles/zshrc \
    && echo "source /gcloud/load-credentials.sh" >> $HOME/dotfiles/zshrc 

    
# install zsh plugins - it can fail due to download problems
# and require you to re-run the build command. 
# Thus better run in a separate layer for caching
RUN export TERM=dumb \
    && /bin/zsh -ic 'exit' < /dev/null \
    echo "Finished"
#-----------------------------------------------------------------------------
# default terminal configuration and customization
#-----------------------------------------------------------------------------
# open a tmux terminal or reattach whenever the container starts
CMD ["tmux", "new-session", "-A", "-s main"] 
