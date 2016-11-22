using NUnit.Framework;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using Should;

namespace UnitTestProject1
{
    [TestFixture]
    public class test1
    {
        [Test]
        public void should_be_true()
        {
            var a = true;
            a.ShouldBeTrue();
        }
    }
}
