# piPipes, a set of pipelines for PIWI-interacting RNA (piRNA) and transposon analysis
# Copyright (C) 2014  Bo Han, Wei Wang, Zhiping Weng, Phillip Zamore
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.

OUTDIR=$1
EXT_LEN=$2
BIGWIG_FILES="$3"
para_file=$OUTDIR/$INTERSECT_OUTDIR/intersect.para && rm -rf $para_file # delete previous generated para file, but keeping the .complete file so that ParaFly would resume
. $COMMON_FOLDER/genomic_features # reading the information to intersect with, as well as some other annotation files

if [ "$#" == "3" ]; 
then
	# if user has defined customer BED files, add them to TARGETS
	[[ ! -z $USER_DEFINED_BED_FILES ]] &&  eval `echo $USER_DEFINED_BED_FILES | awk 'BEGIN{FS=","}{printf "export USER_DEFINED_BEDS=(" ; ;for (i=1;i<=NF;++i) printf "\"%s\" ", $i; printf ")\n";}'` && \
	for j in "${USER_DEFINED_BEDS[@]}"; do
		i=`readlink -f $j` && \
		VAR_NAME1=`basename $i` && VAR_NAME2=${VAR_NAME1%.bed*} && VAR_NAME=${VAR_NAME2/./_}
		[[ -f $i ]] && eval "export ${VAR_NAME}=`readlink -f $i`" && TARGETS=("${TARGETS[@]}" ${VAR_NAME}) || echo2 "cannot file user defined file $i as regular file" "warning"
	done
	for t in ${TARGETS[@]}
	do \
		echo "bwtool agg ${EXT_LEN}:${EXT_LEN} -starts -long-form=${t}start,'PoissonPvalue,FoldEnriched,logLR' ${!t} $BIGWIG_FILES /dev/stdout | awk 'BEGIN{OFS=\"\\t\"}{if (\$(NF-1)>0) --\$(NF-1); print \$0}' > $OUTDIR/${t}.starts.txt && Rscript --slave ${PIPELINE_DIRECTORY}/bin/piPipes_draw_aggregate.R $OUTDIR/${t}.starts.txt $PDF_DIR/${t}.starts ${t}.TSS " >> $para_file
		echo "bwtool agg ${EXT_LEN}:${EXT_LEN} -ends -long-form=${t}end,'PoissonPvalue,FoldEnriched,logLR' ${!t} $BIGWIG_FILES /dev/stdout | awk 'BEGIN{OFS=\"\\t\"}{if (\$(NF-1)>0) --\$(NF-1); print \$0}' > $OUTDIR/${t}.ends.txt && Rscript --slave ${PIPELINE_DIRECTORY}/bin/piPipes_draw_aggregate.R $OUTDIR/${t}.ends.txt $PDF_DIR/${t}.ends ${t}.TES " >> $para_file
		echo "bwtool agg ${EXT_LEN}:${EXT_LEN}:${EXT_LEN} -meta-scale-all -long-form=${t}meta,'PoissonPvalue,FoldEnriched,logLR' ${!t} $BIGWIG_FILES /dev/stdout | awk 'BEGIN{OFS=\"\\t\"}{if (\$(NF-1)>0) --\$(NF-1); print \$0}' > $OUTDIR/${t}.meta.txt && Rscript --slave ${PIPELINE_DIRECTORY}/bin/piPipes_draw_aggregate.R $OUTDIR/${t}.meta.txt  $PDF_DIR/${t}.meta ${t}.meta " >> $para_file
	#	echo "bwtool agg ${EXT_LEN}:${EXT_LEN}:${EXT_LEN}                 -long-form=${t}meta,'Poisson P value,Fold Enriched,logLR' ${!t} $BIGWIG_FILES $OUTDIR/${t}.meta.txt && Rscript --slave ${PIPELINE_DIRECTORY}/bin/piPipes_draw_aggregate.R $OUTDIR/${t}.meta.txt  $PDF_DIR/${t}.meta ${t}.meta " >> $para_file
	done
	ParaFly -c $para_file -CPU $CPU -failed_cmds ${para_file}.failedCommands 1>&2 && \
	rm -rf ${para_file}*

	PDFs=""
	for t in ${TARGETS[@]}
	do \
			PDFs=${PDFs}" "$PDF_DIR/${t}.starts.pdf" "$PDF_DIR/${t}.ends.pdf" "$PDF_DIR/${t}.meta.pdf
	done

	gs -q -dNOPAUSE -dBATCH -sDEVICE=pdfwrite -sOutputFile=$PDF_DIR/${PREFIX}.features.pdf ${PDFs} && \
	rm -rf ${PDFs} || \
	echo2 "Failed to merge pdf from features intersecting... check gs... Or use your favorarite pdf merge tool by editing line$LINENO in $0" "warning"

else
	shift; shift; shift
	
	t=`basename $1` 
	echo "bwtool agg ${EXT_LEN}:${EXT_LEN} -starts -long-form=\"condition1_starts,${SAMPLE_A_NAME}_Poisson_Pvalue,${SAMPLE_A_NAME}_Fold_Enriched,${SAMPLE_A_NAME}_logLR,${SAMPLE_B_NAME}_Poisson_Pvalue,${SAMPLE_B_NAME}_Fold_Enriched,${SAMPLE_B_NAME}_logLR\" ${1} $BIGWIG_FILES /dev/stdout | awk 'BEGIN{OFS=\"\\t\"}{if (\$(NF-1)>0) --\$(NF-1); print \$0}' > $OUTDIR/${t%.bed}.starts.txt && Rscript --slave ${PIPELINE_DIRECTORY}/bin/piPipes_draw_aggregate.R   $OUTDIR/${t%.bed}.starts.txt $PDF_DIR/${t%.bed}.starts. ${t}.TSS" >> $para_file
	echo "bwtool agg ${EXT_LEN}:${EXT_LEN} -ends -long-form=\"condition1_ends,${SAMPLE_A_NAME}_Poisson_Pvalue,${SAMPLE_A_NAME}_Fold_Enriched,${SAMPLE_A_NAME}_logLR,${SAMPLE_B_NAME}_Poisson_Pvalue,${SAMPLE_B_NAME}_Fold_Enriched,${SAMPLE_B_NAME}_logLR\" ${1} $BIGWIG_FILES /dev/stdout | awk 'BEGIN{OFS=\"\\t\"}{if (\$(NF-1)>0) --\$(NF-1); print \$0}' > $OUTDIR/${t%.bed}.ends.txt && Rscript --slave ${PIPELINE_DIRECTORY}/bin/piPipes_draw_aggregate.R       $OUTDIR/${t%.bed}.ends.txt   $PDF_DIR/${t%.bed}.ends ${t}.TES" >> $para_file
	echo "bwtool agg ${EXT_LEN}:${EXT_LEN}:${EXT_LEN} -meta-scale-all -long-form=\"condition1_meta,${SAMPLE_A_NAME}_Poisson_Pvalue,${SAMPLE_A_NAME}_Fold_Enriched,${SAMPLE_A_NAME}_logLR,${SAMPLE_B_NAME}_Poisson_Pvalue,${SAMPLE_B_NAME}_Fold_Enriched,${SAMPLE_B_NAME}_logLR\" ${1} $BIGWIG_FILES /dev/stdout | awk 'BEGIN{OFS=\"\\t\"}{if (\$(NF-1)>0) --\$(NF-1); print \$0}' > $OUTDIR/${t%.bed}.meta.txt && Rscript --slave ${PIPELINE_DIRECTORY}/bin/piPipes_draw_aggregate.R  $OUTDIR/${t%.bed}.meta.txt   $PDF_DIR/${t%.bed}.meta ${t}.mega" >> $para_file
	
	t=`basename $2`
	echo "bwtool agg ${EXT_LEN}:${EXT_LEN} -starts -long-form=\"condition2_starts,${SAMPLE_A_NAME}_Poisson_Pvalue,${SAMPLE_A_NAME}_Fold_Enriched,${SAMPLE_A_NAME}_logLR,${SAMPLE_B_NAME}_Poisson_Pvalue,${SAMPLE_B_NAME}_Fold_Enriched,${SAMPLE_B_NAME}_logLR\" ${2} $BIGWIG_FILES /dev/stdout | awk 'BEGIN{OFS=\"\\t\"}{if (\$(NF-1)>0) --\$(NF-1); print \$0}' > $OUTDIR/${t%.bed}.starts.txt && Rscript --slave ${PIPELINE_DIRECTORY}/bin/piPipes_draw_aggregate.R   $OUTDIR/${t%.bed}.starts.txt $PDF_DIR/${t%.bed}.starts. ${t}.TSS" >> $para_file
	echo "bwtool agg ${EXT_LEN}:${EXT_LEN} -ends -long-form=\"condition2_ends,${SAMPLE_A_NAME}_Poisson_Pvalue,${SAMPLE_A_NAME}_Fold_Enriched,${SAMPLE_A_NAME}_logLR,${SAMPLE_B_NAME}_Poisson_Pvalue,${SAMPLE_B_NAME}_Fold_Enriched,${SAMPLE_B_NAME}_logLR\" ${2} $BIGWIG_FILES /dev/stdout | awk 'BEGIN{OFS=\"\\t\"}{if (\$(NF-1)>0) --\$(NF-1); print \$0}' > $OUTDIR/${t%.bed}.ends.txt && Rscript --slave ${PIPELINE_DIRECTORY}/bin/piPipes_draw_aggregate.R       $OUTDIR/${t%.bed}.ends.txt   $PDF_DIR/${t%.bed}.ends ${t}.TES" >> $para_file
	echo "bwtool agg ${EXT_LEN}:${EXT_LEN}:${EXT_LEN} -meta-scale-all -long-form=\"condition2_meta,${SAMPLE_A_NAME}_Poisson_Pvalue,${SAMPLE_A_NAME}_Fold_Enriched,${SAMPLE_A_NAME}_logLR,${SAMPLE_B_NAME}_Poisson_Pvalue,${SAMPLE_B_NAME}_Fold_Enriched,${SAMPLE_B_NAME}_logLR\" ${2} $BIGWIG_FILES /dev/stdout | awk 'BEGIN{OFS=\"\\t\"}{if (\$(NF-1)>0) --\$(NF-1); print \$0}' > $OUTDIR/${t%.bed}.meta.txt && Rscript --slave ${PIPELINE_DIRECTORY}/bin/piPipes_draw_aggregate.R  $OUTDIR/${t%.bed}.meta.txt   $PDF_DIR/${t%.bed}.meta ${t}.mega" >> $para_file
	ParaFly -c $para_file -CPU $CPU -failed_cmds ${para_file}.failedCommands 1>&2 && \
	rm -rf ${para_file}*
fi
