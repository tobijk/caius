# Caius Functional Testing Framework

## Summary

Caius is a functional testing framework for the 21st century. It was born out of the need for a contemporary replacement for <a href="http://www.gnu.org/software/dejagnu/">DejaGnu</a>. Caius is written in object-oriented Tcl and provides easy-to-use programming interface to proven testing technologies. Through its versatile reporting system, Caius integrates well with modern CI systems and test management tools.

### Expect

Drive command line applications and automate shell sessions, log into remote systems via Telnet, SSH or the serial line. Caius offers you the power of Expect through a simple, intuitive, object-oriented API.

### Selenium WebDriver

Test Web applications by automating complete browser sessions through the WebDriver interface. Select windows, manage cookies, click, send keystrokes, inject JavaScript and inspect page elements.

### Reporting

Produce clean, accessible HTML reports or make test results available through your favorite CI system. Caius can output test results in different reporting formats and new formats can be added easily.

### Object-Oriented

Caius provides enhancements that make object-oriented programming in Tcl more fun and more productive. Enjoy fine-grained exception handling and create objects that serialize to JSON with a snap.
        
## Usage Scenarios

The combination of Expect and WebDriver makes Caius particularly suitable for building large integration test setups for headless embedded systems, for example in industrial automation environments. If the majority of your systems can be configured and controlled from the command line or a Web-based management console, then Caius can be used to test component functionality and interaction at network scale.

Even if you are dealing with much smaller test environments or if your test assets are mainly written in languages other than Tcl, you can use Caius as a test harness for test execution and report generation.

## Quickstart

Download the source tarball from <a href="https://github.com/tobijk/caius/releases">here</a>. In order to run Caius, you need to install a number of additional packages.
            
### Dependencies

On OpenSUSE, install the required packages with <tt>zypper</tt> by executing the following command:
            
    sudo zypper install tcl tcllib expect tdom

On Debian or Ubuntu, install the dependencies by running <tt>apt-get</tt> instead:

    sudo apt-get install tcl8.6 tcllib tcl-thread itcl3 expect tdom

On some versions of Debian, you may have to install the package <tt>tclthread</tt> instead of <tt>tcl-thread</tt>.

### Installation

Unpack the sources and execute the <tt>install.tcl</tt> script. You should see the following output:

    tobias@neil-vm:~/caius-0.9.1$ sudo ./install.tcl
    * Checking Tcl shell /usr/bin/tclsh...              
    - Check Tcl version >= 8.6:                          ok
    - Check if interpreter is thread-enabled:            ok
    - Check for the Thread package:                      ok
    - Check for tcllib (require json):                   ok
    - Check for [incr Tcl] extension:                    ok
    - Check for Expect:                                  ok
    - Check for tdom extension:                          ok
    * Installing to /usr/local/lib/tcltk/caius...       
    - Copying files:                                     done
            
Next, you should have a look at the <a href="http://caiusproject.com/tutorial/part01.html#writing-tests">tutorial</a> for a brief introduction to writing and executing tests.

