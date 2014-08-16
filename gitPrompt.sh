export PS1=$PS1'\001\e[1;36m\002$(promptParenthesis "start")'
export PS1=$PS1'\001\e[1;36m\002$(showGitBranch)'
export PS1=$PS1'\001\e[1;32m\002$(showUnpushedCommits)'
export PS1=$PS1'\001\e[1;31m\002$(showBehindCommits)'
export PS1=$PS1'\001\e[1;36m\002$(promptParenthesis "end")'
export PS1=$PS1'\001\e[1;31m\002$(showGitUnCommited)'
export PS1=$PS1'\001\e[1;32m\002$(showAddedFiles)'
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
    nbrDurty=0
    for file in $status; do
      firstLetters=${file:0:2}
      if [[ $firstLetters = " M" || $firstLetters = "??" ]]; then
	nbrDurty=$((nbrDurty+1))
      fi
    done

    if [ $nbrDurty -gt 0 ]; then
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
      allCommits=$(git log $distantRepoName/$currentBranch..$currentBranch)
      nbrCommits=0
      for commit in $allCommits; do
	if [ $(echo $commit | cut -d' ' -f1) = "commit" ]; then
	  nbrCommits=$((nbrCommits+1))
	fi
      done
      if [ $nbrCommits -gt 0 ]; then
	echo "↑$nbrCommits"
      fi
  fi
}

showAddedFiles (){
  currentBranch=$(showGitBranch)
  if [[ -d .git && $currentBranch != "" ]]; then
    status=$(git status --porcelain)
    nbrAdded=0
    for file in $status; do
      if [ ${file:0:1} = "M" ]; then
	nbrAdded=$((nbrAdded+1))
      fi
    done

    if [ $nbrAdded -gt 0 ]; then
      echo "+"
    fi
  fi
}

showBehindCommits () {
  if [ -f /tmp/gitPrompt.save ]; then
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
  if [[ -d .git && $currentBranch != "" ]]; then
    allBehinds=$(git log $currentBranch..$distantRepoName/$currentBranch)
    nbrBehind=0
    for commit in $allBehinds; do
      if [ $(echo $commit | cut -d' ' -f1) = "commit" ]; then
	nbrBehind=$((nbrBehind+1))
      fi
    done
    if [ $nbrBehind -gt 0 ]; then
      echo "↓$nbrBehind"
    fi
  fi
}
