using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;

namespace webapi_netcore.Controllers {

[Route("/")]    
public class HomeController : Controller
{
        public ActionResult Index()
        {
            return Content("Welcome to my Api!");
        }
    }

}