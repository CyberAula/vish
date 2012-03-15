# encoding: utf-8

namespace :license do
  LICENSE_HEADER = <<-EOS
# Copyright 2011-2012 Universidad Politécnica de Madrid and Agora Systems S.A.
#
# This file is part of ViSH (Virtual Science Hub).
#
# ViSH is free software: you can redistribute it and/or modify
# it under the terms of the GNU Affero General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# ViSH is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU Affero General Public License for more details.
#
# You should have received a copy of the GNU Affero General Public License
# along with ViSH.  If not, see <http://www.gnu.org/licenses/>.

  EOS
  LICENSE_DIRS = %w( app/controllers app/models )

  desc "Add license file in all controllers and models"
  task :add do
    LICENSE_DIRS.each do |dir|
      Dir[File.join(Rails.root, dir, '*')].each do |file|
        content = File.new(file, 'r').read
        next if content.include?(LICENSE_HEADER)
        File.new(file, 'w').write(LICENSE_HEADER + content)
      end
    end
  end

  task :remove do
    LICENSE_DIRS.each do |dir|
      Dir[File.join(Rails.root, dir, '*')].each do |file|
        content = File.new(file, 'r').read
        File.new(file, 'w').write(content.gsub(LICENSE_HEADER, ""))
      end
    end
  end
end
