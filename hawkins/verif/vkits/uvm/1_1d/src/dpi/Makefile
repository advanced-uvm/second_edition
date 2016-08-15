#-*- mode: makefile;-*-
# ******************************************************************************
# * CAVIUM NETWORKS CONFIDENTIAL                                               *
# *                                                                            *
# *                         PROPRIETARY NOTE                                   *
# *                                                                            *
# *  This software contains information confidential and proprietary           *
# *  to Cavium Networks.  It shall not be reproduced in whole or in            *
# *  part, or transferred to other documents, or disclosed to third            *
# *  parties, or used for any purpose other than that for which it was         *
# *  obtained, without the prior written consent of Cavium Networks.           *
# *  (c) 2010, Cavium Networks.  All rights reserved.                          *
# *                                                                            *
# ******************************************************************************
# * File        : Makefile
# * Author      : jschroeder
# * Description :
# *
# ******************************************************************************

ifndef DVTOOLS_DIR
export DVTOOLS_DIR := $(shell find_dvtools)
endif


EMPTY:=
SP :=$(EMPTY) $(EMPTY)

ROOT_DIR = $(shell project_dir --project)

override LIB_DIR = ../../../../../lib

#point to a directory where it won't find anything
override SRC_DIRS=../..

#only build this one file which includes all the other files
override CC_FILES=uvm_dpi.cc

include $(DVTOOLS_DIR)/lib/Makefile.vkit
