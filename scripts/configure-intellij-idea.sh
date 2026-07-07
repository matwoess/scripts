#!/bin/bash

bold=$(tput bold)
norm=$(tput sgr0)

studioloc="/opt/intellij-idea"
proploc="$studioloc/bin/idea.properties"
shloc="$studioloc/bin/idea.sh"
confloc="\${user.home}\/.config\/intellij-idea"
sysloc="\${user.home}\/.cache\/intellij-idea"
selloc="config\/intellij-idea"

configideaprops() {
  echo "${bold}::${norm} configuring ${bold}idea.properties${norm}" 
  echo "${bold}::${norm} creating backup of original file for edits"
  cp $proploc{,.edit}
  
  #make edits
  echo "editing ${bold}config${norm} dir..."
  orig="# idea.config.path=\${user.home}\/.IntelliJIdea\/config"
  repl="idea.config.path=$confloc\/config"
  sed -i -e "s/$orig/$repl/g" $proploc.edit
  echo "editing ${bold}system${norm} dir..."
  orig="# idea.system.path=\${user.home}\/.IntelliJIdea\/system"
  repl="idea.system.path=$sysloc\/system"
  sed -i -e "s/$orig/$repl/g" $proploc.edit
  echo "editing ${bold}plugins${norm} dir..."
  orig="# idea.plugins.path=\${idea.config.path}\/plugins"
  repl="idea.plugins.path=\${idea.config.path}\/plugins"
  sed -i -e "s/$orig/$repl/g" $proploc.edit
  echo "editing ${bold}log${norm} dir..."
  orig="# idea.log.path=\${idea.system.path}\/log"
  repl="idea.log.path=\${idea.system.path}\/log"
  sed -i -e "s/$orig/$repl/g" $proploc.edit
  
  #show diff and prompt for confirmation
  if cmp -s $proploc{,.edit}; then 
    echo "${bold}::${norm} no changes detected -> skipping"
    rm $proploc.edit    
  else
    diff --color $proploc{,.edit}
    read -p "Apply changes (y/n)? " -n 1 -r
    echo
    case "$REPLY" in
      y|Y) 
        echo "${bold}::${norm} replacing original file with edited version"
        mv $proploc{.edit,}
        ;;
      n|N) 
        echo "${bold}::${norm} removing edited file"
        rm $proploc.edit
        ;;
      *) echo "invalid choice" && exit 1;;
    esac
  fi
}

configstudiosh() {
  echo "${bold}::${norm} configuring ${bold}idea.sh${norm}"
  echo "${bold}::${norm} creating backup of original file for edits"
  cp $shloc{,.edit}
  
  #make edits
  echo "editing ${bold}idea.paths.selector${norm}..."
  orig="-Didea.paths.selector=IntelliJIdea.* "
  repl="-Didea.paths.selector=$selloc "
  sed -i -e "s/$orig/$repl/g" $shloc.edit
  
  #show diff and prompt for confirmation
  if cmp -s $shloc{,.edit}; then 
    echo "${bold}::${norm} no changes detected -> skipping"
    rm $shloc.edit
  else
    diff --color $shloc{,.edit}
    read -p "Apply changes (y/n)? " -n 1 -r
    echo
    case "$REPLY" in
      y|Y) 
        echo "${bold}::${norm} replacing original file with edited version"
        mv $shloc{.edit,}
        ;;
      n|N) 
        echo "${bold}::${norm} removing edited file"
        rm $shloc.edit
        ;;
      *) echo "invalid choice" && exit 1;;
    esac
  fi
}

cleanup() {
  echo "${bold}::${norm} cleaning up ghost directory in ${bold}\$HOME${norm}"
  if ls ~/.IntelliJIdea* >/dev/null 2>&1; then
    rm -r ~/.IntelliJIdea*
  else
    echo "no directory found"
  fi
}

configideaprops
echo "------------------------"
configstudiosh
echo "------------------------"
cleanup

echo "[  DONE  ]"
