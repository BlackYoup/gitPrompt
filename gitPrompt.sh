export PS1=$PS1'\001\e[1;36m\002$(promptParenthesis "start")'
export PS1=$PS1'\001\e[1;36m\002$(showGitBranch)'
export PS1=$PS1'\001\e[1;32m\002$(showUnpushedCommits)'
export PS1=$PS1'\001\e[1;31m\002$(showBehindCommits)'
export PS1=$PS1'\001\e[1;36m\002$(promptParenthesis "end")'
export PS1=$PS1'\001\e[1;31m\002$(showGitUnCommited)'
export PS1=$PS1'\001\e[1;32m\002$(showReadyToCommit)'
export PS1=$PS1'\001\e[1;33m\002$(showGitStashed)'

refreshGitFetch=3600
distantRepoName="origin"

isGit() {
  if [ "$(git rev-parse --git-dir 2>/dev/null)" != "" ]; then
    echo "yes"
  else
    echo "no"
  fi
}

promptParenthesis () {
  if [ $(isGit) = "yes" ]; then
    if [ $1 = "start" ]; then
      echo "("
    else
      echo ")"
    fi
  fi
}

showGitBranch () {
  if [ $(isGit) = "yes" ]; then
    branch=$(git branch 2>/dev/null| sed -n '/^\*/s/^\* //p')
  else
    branch=""
  fi

  echo $branch
}

showGitUnCommited (){
  if [ $(isGit) = "yes" ]; then
    status=$(git status --porcelain)
    modified=$(echo "$status" | cut -d' ' -f2)
    added=$(echo "$status" | cut -d' ' -f1)

    isModified="no"
    isAdded="no"

    for mod in $modified; do
      if [ $mod = "M" ]; then
        isModified="yes"
        break
      fi
    done

    if [ $isModified = "no" ]; then
      for ad in $added; do
        if [ $ad = "??" ] || [ $ad = "MM" ]; then
          isAdded="yes"
          break
        fi
      done
    fi

    if [ $isModified = "yes" ] || [ $isAdded = "yes" ] ; then
      durty="*"
    else
      durty=""
    fi
    echo "$durty"
  fi
}

showGitStashed (){
  branch=$(showGitBranch)
  if [[ $(isGit) = "yes" && $branch != "" && $(git stash list | grep "$branch" | tail -n1) != "" ]]; then
    stashed=" ~"
  else
    stashed=""
  fi

  echo $stashed
}

showUnpushedCommits (){
  currentBranch=$(showGitBranch)
  if [[ $(isGit) = "yes" && "$currentBranch" != "" ]]; then
      remotes=$(git remote)
      remoteExist=$(remoteBranchExists)

      if [ "$remotes" != "" ]; then
        if [ $(remoteBranchExists) = "yes" ]; then
          allCommits=$(git log $distantRepoName/$currentBranch..$currentBranch --format="%h" 2>/dev/null | cut -d' ' -f1)
        else
          allCommits=$(git log master..HEAD --format="%h" )
        fi
      else
        allCommits=$(git log --format="%h" | cut -d' ' -f1)
      fi

      nbrCommits=0

      for commit in $allCommits; do
        nbrCommits=$((nbrCommits+1))
      done

      if [ $nbrCommits -gt 0 ]; then
        echo "↑$nbrCommits"
      fi
  fi
}

showReadyToCommit (){
  currentBranch=$(showGitBranch)
  if [[ $(isGit) = "yes" && "$currentBranch" != "" ]]; then
    status=$(git status --porcelain | cut -d' ' -f1)

    isReady="no"

    for stat in $status; do
      if [ $stat = "M" ] || [ $stat = "MM" ] ; then
        isReady="yes"
        break
      fi
    done

    if [ $isReady = "yes" ]; then
      echo "+"
    fi
  fi
}

showBehindCommits () {
  if [ $(isGit) = "yes" ]; then
    pathFromGit=$(git rev-parse --git-dir)
    if [ "$pathFromGit" = ".git" ]; then
      path=$(pwd)"/.git"
    else
      path=$pathFromGit
    fi
    if [ -f /tmp/gitPrompt.save ] && [ "$(git remote)" != "" ]; then
      saveContent="$(cat /tmp/gitPrompt.save | cut -d' ' -f1)"
      curTime=$(($(date +%s)-$refreshGitFetch))

      last=0
      index=0

      for repo in $saveContent; do
	index=$((index+1))
        if [ "$(echo $repo | cut -d':' -f1)" = $path ]; then
          last=$(echo $repo | cut -d':' -f2)
          break
        fi
      done

      if [ $curTime -gt $last ]; then
        $(git fetch > /dev/null 2>&1)
        if [ $last -gt 0 ]; then
          $(sed -i "${index}d" /tmp/gitPrompt.save)
        fi
        $(echo "$path:$(date +%s)" >> /tmp/gitPrompt.save)
      fi
    else
      $(git fetch > /dev/null 2>&1)
      $(echo "$path:$(date +%s)" >> /tmp/gitPrompt.save)
    fi
  fi

  currentBranch=$(showGitBranch)
  if [ $(isGit) = "yes" ] && [ "$currentBranch" != "" ] && [ "$(git remote)" != "" ] && [ $(remoteBranchExists) = "yes" ]; then
    allBehinds=$(git log $currentBranch..$distantRepoName/$currentBranch --format="%h" 2>/dev/null | cut -d' ' -f1)
    nbrBehind=0
    for commit in $allBehinds; do
      nbrBehind=$((nbrBehind+1))
    done

    if [ $nbrBehind -gt 0 ]; then
      echo "↓$nbrBehind"
    fi
  fi
}

remoteBranchExists (){
  remoteBranch=$(git branch -r)
  curBranch="$(showGitBranch)"
  ret="no"

  for branch in $remoteBranch; do
    if [ $branch = $distantRepoName"/""$curBranch" ]; then
      ret="yes"
      break
    fi
  done

  echo $ret
}
