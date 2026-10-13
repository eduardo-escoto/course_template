# Course repo commands. Run from the repo root.
#
#   Build (all output goes to <dir>/build/, same settings as the VS Code tasks)
#     make                     build everything (homework + notes)
#     make hw2 / make lec03    build one document -> homework/hw2/build/hw2.pdf, notes/03-*/build/lec03.pdf
#     make homework / notes    build all of one kind
#     make watch-hw2           rebuild on every save (Ctrl+C to stop); works for lecNN too
#     make clean-hw2 / clean   remove aux files, keep the PDFs
#     make distclean           remove every build/ folder (PDFs too)
#
#   Scaffold
#     make new-hw N=3 [DUE="Mon Oct 19, 11:59 PM PT"]
#     make new-lec TOPIC="Junction Trees" [N=6] [DATE="October 13, 2026"]   (DATE="" for none)
#     make slides              file "Lecture NN[ - post].pdf" dropped into course/slides/

LATEXMK := latexmk -pdf -synctex=1 -interaction=nonstopmode -file-line-error -outdir=build

HWS  := $(sort $(basename $(notdir $(wildcard homework/hw*/hw*.tex))))
LECS := $(sort $(basename $(notdir $(wildcard notes/[0-9][0-9]-*/lec[0-9][0-9].tex))))
DOCS := $(HWS) $(LECS)

# directory holding a document: $(call docdir,hw2) -> homework/hw2
docdir = $(patsubst %/,%,$(dir $(wildcard homework/$(1)/$(1).tex notes/[0-9][0-9]-*/$(1).tex)))

.PHONY: all homework notes clean distclean new-hw new-lec slides \
        $(DOCS) $(addprefix watch-,$(DOCS)) $(addprefix clean-,$(DOCS))

all: $(DOCS)
homework: $(HWS)
notes: $(LECS)

# latexmk tracks dependencies itself, so these always run and it decides what to rebuild.
$(DOCS):
	cd $(call docdir,$@) && $(LATEXMK) $@.tex

$(addprefix watch-,$(DOCS)): watch-%:
	cd $(call docdir,$*) && $(LATEXMK) -pvc -view=none $*.tex

$(addprefix clean-,$(DOCS)): clean-%:
	cd $(call docdir,$*) && latexmk -c -outdir=build $*.tex

clean: $(addprefix clean-,$(DOCS))

distclean:
	rm -rf homework/*/build notes/*/build

new-hw:
ifndef N
	$(error usage: make new-hw N=3 [DUE="..."])
endif
	@./scripts/course.sh new-hw "$(N)" $(if $(DUE),"$(DUE)")

# N is passed as "" when only DATE is given, so the script still auto-numbers.
new-lec:
ifndef TOPIC
	$(error usage: make new-lec TOPIC="Topic Name" [N=6] [DATE="..."])
endif
	@./scripts/course.sh new-lec "$(TOPIC)" \
	  $(if $(N),"$(N)",$(if $(filter undefined,$(origin DATE)),,"")) \
	  $(if $(filter undefined,$(origin DATE)),,"$(DATE)")

slides:
	@./scripts/course.sh slides
