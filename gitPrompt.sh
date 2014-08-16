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

promptParenthesis () {
  if [ -d .git ]; then
    if [ $1 = "start" ]; then
      echo "("
    else
      echo ")"
    fi
  fi
}

showGitBranch () {
  if [ -d .git ]; then
    branch=$(git branch 2>/dev/null| sed -n '/^\*/s/^\* //p')
  else
    branch=""
  fi

  echo $branch
}

showGitUnCommited (){
  if [ -d .git ]; then
    status=$(git status --porcelain)
    modified=$(echo "$status" | cut -d' ' -f2)
    added=$(echo "$status" | cut -d' ' -f1)

    nbrModified=0
    nbrAdded=0

    for mod in $modified; do
      if [ $mod = "M" ]; then
	nbrModified=$((nbrModified+1))
      fi
    done


    if [ $nbrModified -eq 0 ]; then
      for ad in $added; do
	if [ $ad = "??" ] || [ $ad = "MM" ]; then
	  nbrAdded=$((nbrAdded+1))
	fi
      done
    fi

    if [ $nbrModified -gt 0 ] || [ $nbrAdded -gt 0 ] ; then
      durty="*"
    else
      durty=""
    fi
    echo "$durty"
  fi
}

showGitStashed (){
  branch=$(showGitBranch)
  if [[ -d .git && $branch != "" && $(git stash list | grep $branch | tail -n1) != "" ]]; then
    stashed=" ~"
  else
    stashed=""
  fi
  
  echo $stashed
}

showUnpushedCommits (){
  currentBranch=$(showGitBranch)
  if [[ -d .git && $currentBranch != "" ]]; then
      remotes=$(git remote)

      if [ "$remotes" != "" ]; then
	allCommits=$(git log $distantRepoName/$currentBranch..$currentBranch --format="%h" | cut -d' ' -f1)
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
  if [[ -d .git && $currentBranch != "" ]]; then
    status=$(git status --porcelain | cut -d' ' -f1)
    nbrReady=0
    for stat in $status; do
      if [ $stat = "M" ] || [ $stat = "MM" ] ; then
       nbrReady=$((nbrReady+1))
      fi
    done

    if [ $nbrReady -gt 0 ]; then
      echo "+"
    fi
  fi
}

showBehindCommits () {
  if [ -d .git ] && [ -f /tmp/gitPrompt.save ] && [ "$(git remote)" != "" ]; then
    last=$(cat /tmp/gitPrompt.save)
    curTime=$(($(date +%s)-$refreshGitFetch))
    
    if [ $curTime -gt $last ]; then
      $(git fetch > /dev/null 2>&1)
      $(echo "$(date +%s)" > /tmp/gitPrompt.save)
    fi
  else
    $(git fetch > /dev/null 2>&1)
    $(echo "$(date +%s)" > /tmp/gitPrompt.save)
  fi

  currentBranch=$(showGitBranch)

  if [ -d .git ] && [ $currentBranch != "" ] && [ "$(git remote)" != "" ]; then
    allBehinds=$(git log $currentBranch..$distantRepoName/$currentBranch --format="%h" | cut -d' ' -f1)
    nbrBehind=0
    for commit in $allBehinds; do
      nbrBehind=$((nbrBehind+1))
    done

    if [ $nbrBehind -gt 0 ]; then
      echo "↓$nbrBehind"
    fi
  fi
}
