package Jimbob;

import ij.ImagePlus;
import ij.gui.Plot;
import ij.gui.PlotWindow;
import ij.io.FileSaver;

import javax.swing.*;
import java.awt.*;
import java.util.Arrays;
import java.util.List;

public class myPlot {
    Plot plot;
    int plotCount = 0;
    final List<Color> mycolour = Arrays.asList(
            new Color(0.0f,0.4470f,0.7410f),
            new Color(0.8500f,0.3250f,0.0980f),
            new Color(0.9290f,0.6940f,0.1250f),
            new Color(0.4940f,0.1840f,0.5560f),
            new Color(0.4660f,0.6740f,0.9330f),
            new Color(0.6350f,0.0780f,0.1840f));

    double minX = Double.MAX_VALUE,maxX = -Double.MAX_VALUE,minY = Double.MAX_VALUE,maxY = -Double.MAX_VALUE;


    myPlot(String header, String xAxis, String yAxis){
        plot = new Plot(header, xAxis, yAxis);
        plot.setFrameSize(400, 250);
        PlotWindow.noGridLines = true;

        Font myriad = new Font("Myriad Pro", Font.BOLD, 40);
        plot.setAxisLabelFont(myriad.getStyle(), myriad.getSize2D());
        plot.setFont(myriad);


    }

    void addLine(double[] xVals,double[] yVals){
        plot.setLineWidth(2.0f);
        plot.setColor(mycolour.get(plotCount%mycolour.size()));
        plot.add("line",xVals.clone(), yVals.clone());
        plotCount++;

        for(double x:xVals){
            if(x<minX)minX = x;
            if(x>maxX)maxX = x;
        }
        for(double y:yVals){
            if(y<minY)minY = y;
            if(y>maxY)maxY = y;
        }
    }

    void addNormalizedLine(double[] xVals,double[] yVals){
        plot.setLineWidth(2.0f);
        plot.setColor(mycolour.get(plotCount%mycolour.size()));
        double max = Arrays.stream(yVals).max().getAsDouble();

        for(int i=0;i<yVals.length;i++)yVals[i] = yVals[i]/max;

        plot.add("line",xVals.clone(), yVals.clone());
        plotCount++;

        for(double x:xVals){
            if(x<minX)minX = x;
            if(x>maxX)maxX = x;
        }
        for(double y:yVals){
            if(y<minY)minY = y;
            if(y>maxY)maxY = y;
        }
    }

    void overlay(double[] xVals,double[] yVals){
        plot.setLineWidth(1.5f);
        plot.setColor(Color.BLACK);
        plot.add("line",xVals.clone(), yVals.clone());

        for(double x:xVals){
            if(x<minX)minX = x;
            if(x>maxX)maxX = x;
        }
        for(double y:yVals){
            if(y<minY)minY = y;
            if(y>maxY)maxY = y;
        }
    }


    void display(boolean includeZero){
        setPlotLimitsWithYBuffer(includeZero);
        SwingUtilities.invokeLater(plot::show);
    }

    void save(String fileName,boolean includeZero){
        setPlotLimitsWithYBuffer( includeZero);
        ImagePlus plotImage = plot.makeHighResolution("", 1.0f, true, false);
        fileName = fileName.endsWith(".png")?fileName:fileName+".png";
        new FileSaver(plotImage).saveAsPng(fileName);
    }


    void setPlotLimitsWithYBuffer(boolean includeZero) {
        plot.setLimitsToFit(true);
        plot.draw();

        if (includeZero) {
            minX = Math.min(minX, 0.0);
            minY = Math.min(minY, 0.0);
            maxX = Math.max(maxX, 0.0);
            maxY = Math.max(maxY, 0.0);
        }


        double yPad = (maxY - minY) * 0.05;
        if (!Double.isFinite(yPad) || yPad <= 0.0) {
            yPad = 1.0;
        }

        plot.setLimits(minX, maxX, minY - yPad, maxY + yPad);

        plot.setLineWidth(1.5f);
        double[] xVals = {minX,maxX};
        double[] yVals = {minY - yPad,maxY + yPad};
        double[] zeros = {0.0,0.0};
        plot.setColor(Color.BLACK);
        plot.add("line",xVals.clone(), zeros.clone());
        plot.add("line",zeros.clone(), yVals.clone());
        plot.draw();
    }



}
