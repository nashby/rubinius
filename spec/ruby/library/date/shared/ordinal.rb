# reference:
# October 1582 (the Gregorian calendar, Civil Date)
#   S   M  Tu   W  Th   F   S
#       1   2   3   4  15  16
#  17  18  19  20  21  22  23
#  24  25  26  27  28  29  30
#  31

describe :date_ordinal, :shared => true do

  ruby_version_is "" ... "1.9" do
    it "should be able to construct a Date object from an ordinal date" do
      # October 1582 (the Gregorian calendar, Ordinal Date in 1.8)
      #   S   M  Tu   W  Th   F   S
      #     274 275 276 277 288 289
      # 290 291 292 293 294 295 296
      # 297 298 299 300 301 302 303
      # 304
      Date.send(@method, 1582, 274).should == Date.civil(1582, 10,  1)
      Date.send(@method, 1582, 277).should == Date.civil(1582, 10,  4)
      lambda { Date.send(@method, 1582, 278) }.should raise_error(ArgumentError)
      lambda { Date.send(@method, 1582, 287) }.should raise_error(ArgumentError)
      Date.send(@method, 1582, 288).should == Date.civil(1582, 10, 15)
      Date.send(@method, 1582, 287, Date::ENGLAND).should == Date.civil(1582, 10, 14, Date::ENGLAND)
    end
  end

  ruby_version_is "1.9" do
    it "should be able to construct a Date object from an ordinal date" do
      # October 1582 (the Gregorian calendar, Ordinal Date in 1.9)
      #   S   M  Tu   W  Th   F   S
      #     274 275 276 277 278 279
      # 280 281 282 283 284 285 286
      # 287 288 289 290 291 292 293
      # 294
      Date.send(@method, 1582, 274).should == Date.civil(1582, 10,  1)
      Date.send(@method, 1582, 277).should == Date.civil(1582, 10,  4)
      Date.send(@method, 1582, 278).should == Date.civil(1582, 10, 15)
      Date.send(@method, 1582, 287, Date::ENGLAND).should == Date.civil(1582, 10, 14, Date::ENGLAND)
    end
  end
end
