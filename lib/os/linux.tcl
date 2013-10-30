#
#   Caius Functional Testing Framework
#
#   Copyright 2013 Tobias Koch <tobias.koch@gmail.com>
#
#   This program is free software; you can redistribute it and/or modify
#   it under the terms of the GNU General Public License as published by
#   the Free Software Foundation; either version 2 of the License, or
#   (at your option) any later version.
#
#   This program is distributed in the hope that it will be useful,
#   but WITHOUT ANY WARRANTY; without even the implied warranty of
#   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#
#   See the LICENSE file in the source distribution for more information.
#

namespace eval OS {

    namespace export \
        terminate \
        kill \
        process_exists

    namespace ensemble create

    proc terminate {pid} {
        catch {
            exec kill -15 $pid
        }
    }

    proc kill {pid} {
        catch {
            exec kill -9 $pid
        }
    }

    proc process_exists {pid} {
        if {[file exists "/proc/$pid"]} {
            return 1
        }

        return 0
    }
}

