---
title: \texttt{ltl2ba}
subtitle: Un compilateur de formules LTL en automate de Büchi généralisés
author:
  - Emile ROLLEY
  - Thomas MORIN
institute: Université de Bordeaux
date: 12 mai 2022
language: fr-FR
fontfamily: librebaskerville
sansfont: librebaskerville
fontsize: 11pt
theme: default
colortheme: spruce
fonttheme: serif
linkcolor: #007bbf
header-includes:
- |
  ```{=latex}
  \usepackage[utf8]{inputenc}
  \usepackage{amsmath}
  \usepackage[dvipsnames]{xcolor}
  \usepackage{pmboxdraw}
  \usepackage{tikz}
    \usetikzlibrary{positioning}
    \usetikzlibrary{automata}
    \usetikzlibrary{arrows}
    \tikzset{
        ->, % makes the edges directed
        node distance=3cm, % specifies the minimum distance between two nodes. Change if necessary.
        every state/.style={thick, draw=Green, fill=Green!10}, % sets the properties for each ’state’ node
        initial text=$ $, % sets the text that appears on the start arrow
    }

  \def\term #1{{\color{Purple}\texttt{#1}}}
  \def\spe #1{{\color{Gray}\texttt{#1}}}
  \def\ap #1{\mathnormal{#1}}
  \def\op #1{\mathsf{#1}}
  \setbeamerfont{frametitle}{shape=\bfseries, family=\sffamily}
  ```
---

## Automates de Büchi sur _les transitions_

\pause Même définition que pour un automate de Büchi généralisé :

\begin{center}
  $\mathcal{A} = (S, \rightarrow, S_0, F_1, ..., F_l)$
  \; avec \;
  $\forall i \in \{1, ..,  l\}, \; F_i \subseteq \; \rightarrow$
\end{center}

\pause

\begin{figure}[ht]
    \centering
    \begin{tikzpicture}[auto, on grid, every node]
        \node[state, initial] (x1) at (0, 0) {1};
        \node[state] (x2) at (2, 0) {2};
        \path (x1) edge [loop above] node{$\Sigma$} (x1);
        \path[dashed, thick] (x1) edge [bend left] node{$\ap{p}$} (x2);
        \path[dashed, thick] (x2) edge [loop above] node{$\ap{p}$} (x2);
        \path (x2) edge [bend left] node{$\Sigma$} (x1);
    \end{tikzpicture}
    \caption{Exemple d'automate reconnaissant la formule LTL $\op{GF}\ap{p}$, avec
    en pointillé, les transitions appartenant à l'unique condition d'acceptation.}
\end{figure}

## L'algorithme de traduction

## Un exemple _comparé_ pour $\varphi = \ap{p} \; \op{U}\; \ap{q}$

### Algorithme classique

 On commence par calculer la clôture de la formule :

$cl(\varphi) = \{ \ap{p} \; \op{U}\; \ap{q} \; ; \op{\lnot} (\ap{p} \; \op{U}\; \ap{q}) \; ;
                   \op{X}( \ap{p} \; \op{U}\; \ap{q}) \; ; \op{\lnot} (\op{X}( \ap{p} \; \op{U}\; \ap{q})) \; ; 
                   \ap{p} \; ; \op{\lnot} \ap{p} \; ; \ap{q} \; ; \op{\lnot} \ap{q} \} ;$

$cl(\varphi)$ est constitué de 8 formules (4 formules et leurs négations).


## Un exemple _comparé_ pour $\varphi = \ap{p} \; \op{U}\; \ap{q}$

<center>

On calcule ainsi les états consistants suivants : 

![](./img/pUqNaifWithoutEdges.jpg){height=70%}

</center>

## Un exemple _comparé_ pour $\varphi = \ap{p} \; \op{U}\; \ap{q}$

<center>

On a ainsi l'automate suivant : 

![](./img/pUqNaif.jpg){height=70%}

A peine sale ...

</center>

## Un exemple _comparé_ pour $\varphi = \ap{p} \; \op{U}\; \ap{q}$

### Algorithme Malin

<center>

On commence par mettre l'état initial : c'est la formule actuelle : 

![](./img/pUqEtape1.jpg){height=20%}

</center>

## Un exemple _comparé_ pour $\varphi = \ap{p} \; \op{U}\; \ap{q}$

<center>

On construit ensuite le graphe temporaire pour l'état à considérer : 

![](./img/pUqEtape2.jpg){height=40%}

</center>

## Un exemple _comparé_ pour $\varphi = \ap{p} \; \op{U}\; \ap{q}$

<center>

On ajoute ainsi les vrais états du graphe, en vert : 

![](./img/pUqEtape3.jpg){height=70%}

</center>

## Un exemple _comparé_ pour $\varphi = \ap{p} \; \op{U}\; \ap{q}$

<center>

On a un autre état à considérer, l'état vide. Comme il est réduit et qu'il ne contient pas d'état, il boucle sur lui même : 

![](./img/pUqEtape4.jpg){height=70%}

</center>

## Un exemple _comparé_ pour $\varphi = \ap{p} \; \op{U}\; \ap{q}$

<center>

On retire les états temporaires. Comme il y a un Until, il faut ajouter un ensemble de transitions d'acceptations, en bleu : 

![](./img/pUqEtape5.jpg){height=70%}

</center>






## (Un autre exemple pour $\varphi = \ap{p} \; \op{U}\; \op{FX}\ap{q}$)

## L'implémentation d'Emile

## L'implémentation de Thomas
