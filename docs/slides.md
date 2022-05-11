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
fontsize: 10pt
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

. . .

Même définition que pour un automate de Büchi généralisé :

\begin{center}
  $\mathcal{A} = (S, \rightarrow, S_0, F_1, ..., F_l)$
  \; avec \;
  $\forall i \in \{1, ..,  l\}, \; F_i \subseteq \; \rightarrow$
\end{center}

. . .

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

. . .

### Intuition

Diviser la formule de départ $\varphi$ en sous-formules plus simple (dites
_réduites_) et ajouter une condition d'acceptation pour chaque sous-formule de
la forme $\alpha \op{U} \beta$.

. . .

### Étapes

1. Mise en forme normale négative de $\varphi$.
2. $S_0 = \{ \varphi \}$.
3. Pour chaque état Y dans $S$ :
    - Calculer un graphe orienté temporaire $\mathcal{G}_Y$.
    - Ajouter dans $\mathcal{A}$ les transitions et les nouveaux états
      correspondants grâce à $\mathcal{G}_Y$.

## L'algorithme de traduction

. . .

### Définition (_NNF_)

Une formule est en **forme normale négative** (_NNF_) si elle est constituée
uniquement des sous-formules suivantes :

- $\bot, \ap{p}$ et $\neg \ap{p}$ avec $\ap{p} \in$ AP
- $\op{X}\alpha$ et $\alpha \circledast \beta$ avec $\circledast \in \{\op{U, R, \vee, \wedge}\}$

. . .

### Définition (_ensemble réduit_)

Un ensemble de formules Z est **réduit** si :

- toutes les formules de Z sont **réduites**, c'est-à-dire, de la forme
  $\ap{p}$, $\neg \ap{p}$ ou $\op{X}\alpha$ avec $\ap{p} \in$ AP
- $\bot \notin$ Z, et $\{\ap{p}, \neg \ap{p}\} \nsubseteq$ Z pour tout $\ap{p} \in$ AP.

## L'algorithme de traduction

. . .

### Calcul de $\mathcal{G}_Y$

Soit Y = Z $\cup \{\alpha\}$ où $\alpha$ n'est pas réduite et si possible
maximale (càd.  n'est sous-formule d'aucune autre formule non réduite de Y).
Les arêtes à partir de Y sont :

- Si $\alpha = \alpha_1 \vee \alpha_2$, $Y \rightarrow Z \cup \{\alpha_1\}$ et
  $Y \rightarrow Z \cup \{\alpha_2\}$.
- Si $\alpha = \alpha_1 \wedge \alpha_2$, $Y \rightarrow Z \cup \{\alpha_1, \alpha_2\}$
- Si $\alpha = \alpha_1 \; \op{R} \; \alpha_2$, $Y \rightarrow Z \cup \{\alpha_1, \alpha_2\}$
  et  $Y \rightarrow Z \cup \{\op{X}\alpha, \alpha_2\}$.
- Si $\alpha = \alpha_1 \; \op{U} \; \alpha_2$, $Y \rightarrow Z \cup \{\alpha_2\}$
  et  $Y \rightarrow^{\alpha} Z \cup \{\op{X}\alpha, \alpha_1\}$.

. . .

\text{}\newline

Cette construction est appliquée récursivement jusqu'à ce que toutes les
feuilles du graphe soient réduites.

## L'algorithme de traduction

. . .

### Calcul des transitions à partir de Y

Finalement, une fois $\mathcal{G}_Y$ calculé, sont ajoutées dans $\mathcal{A}$ :

- les transitions suivantes $\{ Y \rightarrow^{\Sigma_{Z}} \text{next}(Z) \; | \; Z \in \text{Red}(Y)\}$
- pour chaque sous-formule $\alpha = \alpha_1 \; \op{U} \; \alpha_2$,
  les conditions d'acceptations $F_\alpha = \{ Y \rightarrow^{\Sigma_{Z}} \text{next}(Z) \; | \; Y \in S, \; Z \in \text{Red}_\alpha(Y)\}$

. . .

Avec,

\begin{align*}
  \text{Red}(Y)           &= \{ Z \text{ réduit} \; | \; Y \rightarrow^{*} Z\}\\
  \text{Red}_{\alpha}(Y)  &= \{ Z \text{ réduit} \; | \; Y \rightarrow^{* \setminus \alpha} Z\}\\
  \text{next}(Z)          &= \{ \alpha \; | \; \op{X}\alpha \in Z\}\\
  \Sigma_Z                &= \bigcap_{\ap{p} \in Z} \Sigma_{\ap{p}} \cap \bigcap_{\neg \ap{p} \in Z} \Sigma_{\neg \ap{p}}
\end{align*}


## Un exemple pour $\varphi = \ap{p} \; \op{U}\; \op{X}\ap{q}$

## (Un autre exemple pour $\varphi = \ap{p} \; \op{U}\; \op{FX}\ap{q}$)

## L'implémentation d'Emile

## L'implémentation de Thomas
