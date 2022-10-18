#!/bin/bash
function set-title() {
	if [[ -z "$ORIG" ]]; then
		ORIG=$PS1
	fi
	TITLE="\[\e]2;$*\a\]"
	PS1=${ORIG}${TITLE}
}

#Fuente: https://www.enmimaquinafunciona.com/pregunta/170744/como-cambiar-el-nombre-de-la-terminal-de-ubuntu
