package Jimbob;

import java.util.ArrayList;
import java.util.Arrays;

public class myThreshold {

    static void firstThreshold(double[][] allData,boolean rising, double threshold, int debounceFrames, ArrayList<Integer> fitTraceNums,ArrayList<Integer> fitPoses){

        fitTraceNums.clear();
        fitPoses.clear();

        for(int partNum = 0;partNum<allData.length;partNum++){
            for(int i = 0;i<=allData[partNum].length-debounceFrames;i++) {
                boolean allTrue = true;
                for(int j=0;j<debounceFrames;j++)
                    if((allData[partNum][i+j]<threshold && rising) || (allData[partNum][i+j]>=threshold && !rising)){
                        allTrue=false;
                        break;
                    }
                if(allTrue){
                    fitTraceNums.add(partNum);
                    fitPoses.add(i);
                    break;
                }
            }
        }
    }


    static void lastThreshold(double[][] allData,boolean risingThreshold, double threshold, int debounceFrames, ArrayList<Integer> fitTraceNums,ArrayList<Integer> fitPoses){

        if (debounceFrames <= 0)return;

        fitTraceNums.clear();
        fitPoses.clear();

        for(int partNum = 0;partNum<allData.length;partNum++){
            boolean currentState = !risingThreshold;
            int lastRising = -1;
            int lastFalling = -1;
            for(int i = 0;i<=allData[partNum].length-debounceFrames;i++) {
                boolean rising = true;
                boolean falling = true;
                for(int j=0;j<debounceFrames;j++) {
                    if ((allData[partNum][i + j] < threshold)) {
                        rising = false;
                    }else if (allData[partNum][i + j] >= threshold){
                        falling = false;
                    }
                }
                if(!currentState && rising) {
                    lastRising = i;
                    currentState = true;
                }if(currentState && falling){
                    lastFalling = i;
                    currentState = false;
                }
            }
            if(risingThreshold && lastRising>=0){
                fitTraceNums.add(partNum);
                fitPoses.add(lastRising);
            } else if(!risingThreshold && lastFalling>=0){
                fitTraceNums.add(partNum);
                fitPoses.add(lastFalling);
            }
        }
    }

    static int singleFirstThreshold(double[] yVals,boolean rising, double threshold, int debounceFrames, boolean percentThreshold){

        if(percentThreshold){
            double min = Arrays.stream(yVals).min().getAsDouble();
            double max = Arrays.stream(yVals).max().getAsDouble();
            threshold = 0.01*threshold*(max-min)+min;
        }

        for(int i = 0;i<=yVals.length-debounceFrames;i++) {
            boolean allTrue = true;
            for(int j=0;j<debounceFrames;j++)
                if((yVals[i+j]<threshold && rising) || (yVals[i+j]>=threshold && !rising)){
                    allTrue=false;
                    break;
                }
            if(allTrue){
                return i;
            }
        }
        return -1;

    }

    static int singleLastThreshold(double[] yVals,boolean risingThreshold, double threshold, int debounceFrames,boolean percentThreshold){

        if (debounceFrames <= 0)return -1;

        if(percentThreshold){
            double min = Arrays.stream(yVals).min().getAsDouble();
            double max = Arrays.stream(yVals).max().getAsDouble();
            threshold = 0.01*threshold*(max-min)+min;
        }


        boolean currentState = !risingThreshold;
        int lastRising = -1;
        int lastFalling = -1;
        for(int i = 0;i<=yVals.length-debounceFrames;i++) {
            boolean rising = true;
            boolean falling = true;
            for(int j=0;j<debounceFrames;j++) {
                if ((yVals[i + j] < threshold)) {
                    rising = false;
                }else if (yVals[i + j] >= threshold){
                    falling = false;
                }
            }
            if(!currentState && rising) {
                lastRising = i;
                currentState = true;
            }if(currentState && falling){
                lastFalling = i;
                currentState = false;
            }
        }


        if(risingThreshold && lastRising>=0)return lastRising;
        else if(!risingThreshold && lastFalling>=0) return lastFalling;

        return -1;
    }

}
