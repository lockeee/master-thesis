%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% TUBthesis.cls
% (c) 2014  Martin Sauer
% Preliminary version
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\NeedsTeXFormat{LaTeX2e}
\ProvidesClass{TUBthesis}

\LoadClass[a4paper,11pt, parskip=false, leqno, numbers=enddot, twoside, toc=bib, openany, numbers=noenddot]{scrbook}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%required packages
%typo
\RequirePackage[utf8x]{inputenc}
\RequirePackage{setspace}
\RequirePackage{scrpage2}
\RequirePackage{microtype}
\RequirePackage{lmodern}
\RequirePackage[T1]{fontenc}

%math
\RequirePackage{amsmath}
\RequirePackage{amsthm}
\RequirePackage{empheq}
\RequirePackage{amssymb}
\RequirePackage{mathtools}
\RequirePackage{xfrac}
\RequirePackage{xstring}
%\RequirePackage{bbm}
%other
\RequirePackage{graphicx}
\RequirePackage{color}
\RequirePackage{enumitem}
\RequirePackage[german, english]{babel}
\RequirePackage{ifthen}
%tikz
\RequirePackage{tikz}
\RequirePackage{pgf}
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%set page margins
\RequirePackage[a4paper, textwidth=37em,textheight=44\baselineskip]{geometry}
\RequirePackage[final, bookmarksopenlevel=section, bookmarksdepth=section]{hyperref}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%variables
\newcommand{\Title}[1]{\newcommand{\vTitle}{#1}}
\newcommand{\Thesis}[1]{\newcommand{\vThesis}{#1}}
\newcommand{\Author}[1]{\newcommand{\vAuthor}{#1}}
\newcommand{\MNumber}[1]{\newcommand{\vMNumber}{#1}}
\newcommand{\Date}[1]{\newcommand{\vDate}{#1}}

\newcommand{\Supervisor}[1]{\newcommand{\vSupervisor}{#1}}
\newcommand{\Referee}[1]{\newcommand{\vReferee}{#1}}
\newcommand{\Language}[1]{\newcommand{\vLanguage}{#1}}
\newcommand{\posvec}[1]{\left(\@tfor\next:=#1\do{\next}\right)}


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Formatting

\KOMAoptions{open=right}

%Modify section headings

\setkomafont{chapter}{\LARGE \bfseries \rmfamily}
\setkomafont{section}{\Large \bfseries \rmfamily}
\setkomafont{subsection}{\large \bfseries \rmfamily}
\addtokomafont{chapterentry}{\rmfamily}

%modify pagestyle, pagemarks and title/author in header
\pagestyle{scrheadings}
\setkomafont{pageheadfoot}{\normalfont\normalcolor\slshape\footnotesize}

\AtBeginDocument{%
%set values for \maketitle
%set values for \hyperref
\hypersetup{%
pdftitle=\vTitle, pdfauthor=\vAuthor, pdfsubject=\vThesis%
}%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
\newtheoremstyle{dotless_theorem}{}{}{\itshape}{}{\bfseries}{}{ }{}
\newtheoremstyle{dotless_definition}{}{}{}{}{\bfseries}{}{ }{}

%theorem environments
\ifthenelse{\equal{\vLanguage}{english}}{%
\theoremstyle{dotless_theorem}%
\newtheorem{theorem}{Theorem}[chapter]%
\newtheorem{lemma}[theorem]{Lemma}%
\newtheorem{proposition}[theorem]{Proposition}%
\newtheorem{corollary}[theorem]{Corollary}%
\theoremstyle{dotless_definition}%
\newtheorem{definition}[theorem]{Definition}%
\newtheorem{example}[theorem]{Example}%
\newtheorem*{remark}{Remark}%
}
{%
\newtheorem{theorem}{Theorem}[chapter]%
\newtheorem{lemma}[theorem]{Lemma}%
\newtheorem{proposition}[theorem]{Proposition}%
\newtheorem{corollary}[theorem]{Corollary}%
\theoremstyle{definition}%
\newtheorem{definition}[theorem]{Definition}%
\newtheorem{example}[theorem]{Example}%
\newtheorem*{remark}{Bemerkung}%
\theoremstyle{dotless_theorem}%
\newtheorem{claim}{Behauptung}%
\theoremstyle{dotless_theorem}%
\newtheorem{conjecture}{Vermutung}
\theoremstyle{dotless_theorem}%
\newtheorem{observation}{Beobachtung}
}%

%
%equation numbering
\numberwithin{equation}{chapter}%
}

%define \AtTheVeryBeginning for typesetting the abstract
\makeatletter
\newcommand\AtTheVeryBeginning[1]{%
\expandafter\gdef
\expandafter\@preamblecmds
\expandafter{\@preamblecmds#1}%
}
\@onlypreamble\AtTheVeryBeginning
\makeatother




%typeset title and abstract

\newcommand{\HRule}{\rule{\linewidth}{.6pt}} % New command to make the lines in the title page

\AtTheVeryBeginning{%
\frontmatter%
\selectlanguage{german}%
\begin{titlepage}%
\pagestyle{empty}%
\begin{center}

\vspace*{.06\textheight}
{\LARGE Technische Universität Berlin \par}\vspace{1.5cm} % University name
\textbf{\Large Master Arbeit}\\[0.5cm] % Thesis type

\HRule \\[0.4cm] % Horizontal line
{\huge \bfseries \vTitle\par}\vspace{0.4cm} % Thesis title
\HRule \\[1.5cm] % Horizontal line
 
\begin{minipage}[t]{0.4\textwidth}
\begin{flushleft} \large
\emph{Autor:}\\
{\vAuthor} % Author name - remove the \href bracket to remove the link
\\[0.4cm]
\emph{Matrikelnummer:}\\
{\vMNumber} % Author name - remove the \href bracket to remove the link

\end{flushleft}
\end{minipage}
\begin{minipage}[t]{0.4\textwidth}
\begin{flushright} \large
\emph{Betreuer und Erstgutachter:} \\
{\vSupervisor} % Supervisor name - remove the \href bracket to remove the link 
\\[0.4cm]
\emph{Zweitgutachter: } \\
{\vReferee} % Supervisor name - remove the \href bracket to remove the link 
\end{flushright}
\end{minipage}\\[2cm]
 
\vfill

\large \textit{Masterarbeit zur Prüfung zum Master of Science}\\[0.3cm] % University requirement text
\textit{an der}\\[0.4cm]
Technische Universität Berlin\\
Institut für Mathematik
\\[1.5cm]
\vfill

{\large \vDate} % Date
%\includegraphics{Logo} % University/department logo - uncomment to place it
 
\vfill
\end{center}

%\begin{center}%
%\vspace*{6\baselineskip}%
%\begin{spacing}{2}%
%{\rmfamily \Huge \bfseries \vTitle}\\%
%\end{spacing}%
%\vspace{3\baselineskip}%
%{\large \begin{spacing}{1.2}%
%Dem Institut f\"ur Mathematik\\%
%der Technischen Universit\"at Berlin\\%
%vorgelegte\\%
%\vspace{1.5\baselineskip}%
%{\Large \bfseries \vThesis}\\%
%\vspace{1.5\baselineskip}%
%von\\%
%{\Large \bfseries \vAuthor}\\%
%Matrikelnummer \vMNumber.\\%
%\vspace{9\baselineskip}%
%\begin{tabular}[h]{lr}%
% Betreuer und Erstgutachter: & \vSupervisor\\%
%Zweitgutachter: & \vReferee\\%
%Tag der Einreichung: & \vDate%
%\end{tabular}%
%\end{spacing}}%
%\end{center}%



\clearpage%
\end{titlepage}%
\cleardoublepage
%----------------------------------------------------------------------------------------
%	DECLARATION PAGE
%----------------------------------------------------------------------------------------

\begin{large}
\noindent \textbf{Eidesstattliche Erklärung}
\end{large}
\bigskip

\noindent Hiermit erkl\"are ich, dass ich die vorliegende Arbeit selbstst\"andig und eigenh\"andig sowie ohne unerlaubte fremde Hilfe und ausschließlich unter Verwendung der aufgef\"uhrten Quellen und Hilfsmittel angefertigt habe.
\vspace{1cm}

\noindent Berlin, den
\\[2cm]
\noindent ...........................................................................\\

\noindent Jonas Neukamm

\cleardoublepage

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

\ifthenelse{\equal{\vLanguage}{german}}{\selectlanguage{german}}{\selectlanguage{german}}%
\input{zusammenfassung.tex}
\tableofcontents%
\pagenumbering{arabic}

\mainmatter%
}


