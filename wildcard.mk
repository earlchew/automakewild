ifndef WILDCARD_MK_
WILDCARD_MK_ := 1

# Copyright (c) 2014 Earl Chew
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#     * Redistributions of source code must retain the above copyright
#       notice, this list of conditions and the following disclaimer.
#     * Redistributions in binary form must reproduce the above copyright
#       notice, this list of conditions and the following disclaimer in the
#       documentation and/or other materials provided with the distribution.
#     * Neither the names of the authors of source code nor the names
#       of the contributors to the source code may be used to endorse or
#       promote products derived from this software without specific
#       prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE FOR ANY
# DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

# Although the Automake documentation provides a rationale for eschewing
# wildcards, there may be occasions where its use is desired:
#
#    http://www.gnu.org/software/automake/manual/html_node/Wildcards.html
#
# This solution creates a list of source files and houses that list in
# a separate file. For example, suppose app_SOURCES is to contain
# a list of source files to build the program app. The following
# artifacts are created:
#
#  app_c.mk	Makefile fragment that constructs and maintains app_c.mk
#  app_c.am	Automake fragment defining app_SOURCES
#
# In the enclosing Makefile.am, the following is required:
#
#    $(eval include $(top_srcdir)/wildcard.mk)               #1
#    ...
#    app_CFLAGS = ...
#    include app_c.am                                        #2
#    $(call WILDCARD_LIB, app_c, app_SOURCES, [a-z]*.c)      #3
#
# Line #1 brings the wildcard Makefile fragment into scope when make
# runs the Makefile.
#
# Line #2 is processed by Automake and brings the definition of app_SOURCES
# into scope when processing Makefile.am. This is important because Automake
# needs to be given a complete list of files that contribute to the target.
#
# Line #3 is processed by make and defines the rules and targets to construct
# and update the app_c.mk and app_c.am files.

WILDCARD_LIB = $(eval \
    $(call WILDCARD_,$(strip \
	$(1)),$(strip \
	$(2)),$(strip \
	$(3)),$(strip \
	$(call WILDCARD_LIB_,$(strip $(2))))))

WILDCARD_TESTS = $(eval \
    $(call WILDCARD_,$(strip \
	$(1)),$(strip \
	$(2)),$(strip \
	$(3)),$(strip \
	$(call WILDCARD_TESTS_,$(strip \
	    $(2)),$(strip \
	    $(subst $$,$$$$,$(strip $(4))))))))

WILDCARD_SRC = $(top_srcdir)/wildcard.mk

define WILDCARD_LIB_
: LIB ; \
printf '%s' '$(1) =' ; \
eval $$$$FIND | sed -e 's/^/  /'  -e '1s/^/ \\\n/' -e '$$$$!s/.*/& \\/' ;
endef

define WILDCARD_TESTS_
: TEST ; \
eval $$$$FIND | \
{ \
  while read FILE ; do \
    printf ' %s \\\n' "$$$${FILE%.*}" ; \
    printf '\n' ; \
    printf '%s_SOURCES = %s\n' "$$$${FILE%.*}" "$$$$FILE" ; \
    printf '%s_LDADD = %s\n' "$$$${FILE%.*}" '$(2)' ; \
  done ; \
  printf '\n' ; \
  printf '%s = \\\n' '$(1)' ; \
} | sed -n -e '/^ /{H;d;}' -e 'p' -e '$$$${g;s/^\n//;s/ \\$$$$//;p;}' ; \
printf '\n' ;
endef

define WILDCARD_
$$(eval -include $(1).mk)
$(1).mk:	$$(WILDCARD_SRC) $(wildcard $(1).am)
	{ \
	  printf '%sinclude %s\n' '-' '$(1).am' ; \
	  printf 'Makefile:	$$$$(wildcard %s)\n' '$(1).am' ; \
	  printf 'ifeq "" "$$$$($(2)_CKSUM_1_)$$$$($(2)_CKSUM_2_)"\n' ; \
	  printf '$(2)_CKSUM_1_=1\n' ; \
	  printf '$(2)_CKSUM_2_=2\n' ; \
	  printf 'endif\n' ; \
	  printf 'ifneq "$$$$($(2)_CKSUM_1_)" "$$$$($(2)_CKSUM_2_)"\n' ; \
	  printf '_ := $$$$(shell rm -f %s)\n' '$(1).am' ; \
	  printf 'endif\n' ; \
	} > "$$@"
$(1).am:
	rm -f "$$@"
	{ \
          FIND="$(strip ( : \
	    $(foreach \
	        N, \
	        $(3), \
	        ; find '$(patsubst %/,%,$(dir $N))' \
	            -maxdepth 1 -name '$(notdir $N)' -print) ) ) \
	    | sed -e 's,^\./,,' | sort" ; \
	  CKSUM="$$$$FIND | cksum" ; \
	  printf '%s = %s\n' '$(2)_CKSUM_1_' "$$$$(eval $$$$CKSUM)" ; \
	  printf '%s = $$$$(shell %s)\n' '$(2)_CKSUM_2_'  "$$$$CKSUM" ; \
	  $(strip $(4)) \
	} > "$$@"
endef

endif # WILDCARD_MK_
